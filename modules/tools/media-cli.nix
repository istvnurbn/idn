{
  den.aspects.media-cli = {
    os = {pkgs, ...}: let
      # Shared by rip-cd and encode-wav
      common = ''
        # read a setting from abcde's config without running abcde
        read_conf() {
            # shellcheck source=/dev/null
            ( . "''${ABCDE_CONF:-$HOME/.abcde.conf}" >/dev/null 2>&1; v=''${!1:-}; printf '%s' "''${v:-$2}" )
        }

        # show one status line: redrawn in place on a terminal, one per update otherwise
        cols=$(tput cols 2>/dev/null || echo 80)
        show() {
            if [[ -t 1 ]]; then
                printf '\r\033[K%s' "''${1:0:cols-1}"
            else
                printf '%s\n' "$1"
            fi
        }
      '';

      # One-line progress wrapper around abcde (reads ~/.abcde.conf).
      rip-cd = pkgs.writeShellApplication {
        name = "rip-cd";
        runtimeInputs = with pkgs; [abcde coreutils gnugrep ncurses];
        # no errexit: a failed abcde or encode makes `wait` return non-zero,
        # which would kill the script before it reports the error
        bashOptions = ["nounset" "pipefail"];
        text = ''
          # rip-cd: run abcde with a one-line progress display.
          #
          #   rip-cd [abcde options]        e.g.  rip-cd          rip-cd -W 2
          #
          # Pass 1 is normal, interactive abcde, CDDB only: pick the match, edit it.
          # Pass 2 resumes from abcde's work folder and rips, encodes, tags and moves
          # without questions. Its output goes to a log; you get one status line.
          # Reads ~/.abcde.conf (and $ABCDE_CONF if set).

          ${common}
          conf_args=()
          [[ -n ''${ABCDE_CONF:-} ]] && conf_args=(-c "$ABCDE_CONF")
          staging=$(read_conf OUTPUTDIR "$HOME/Music/staging")
          outputtype=$(read_conf OUTPUTTYPE flac)
          IFS=, read -ra fmts <<< "$outputtype"

          mkdir -p "$staging/.logs"
          log="$staging/.logs/abcde-$(date +%Y%m%d-%H%M%S).log"

          # ---------- pass 1: interactive CDDB ----------
          # Extra config, sourced by abcde after ~/.abcde.conf: keep the disc in,
          # and on exit write abcde's work folder (abcde.<discid>) for pass 2.
          pass1=$(mktemp); wdfile=$(mktemp)
          trap 'rm -f "$pass1" "$wdfile"' EXIT
          cat > "$pass1" <<'CONF'
          EJECTCD=n
          trap 'printf "%s" "''${ABCDETEMPDIR:-}" > "$RIP_CD_WORKDIR_FILE"' EXIT
          CONF
          RIP_CD_WORKDIR_FILE=$wdfile abcde "''${conf_args[@]}" -c "$pass1" -a cddb "$@" \
              || { echo "rip-cd: CDDB pass failed" >&2; exit 1; }

          workdir=$(<"$wdfile")
          [[ -n $workdir && -d $workdir ]] || { echo "rip-cd: abcde did not report its work folder" >&2; exit 1; }
          status="$workdir/status"

          choice=$(grep -E '^cddb-choice=' "$status" | tail -n 1 | cut -d= -f2)
          # count track numbers, not lines: CDDB splits long titles over several TTITLEn= lines
          tracks=$(grep -oE '^TTITLE[0-9]+=' "$workdir/cddbread.''${choice:-1}" 2>/dev/null | sort -u | wc -l)
          (( tracks > 0 )) || tracks='?'
          album=$(grep -E '^DTITLE=' "$workdir/cddbread.''${choice:-1}" 2>/dev/null | head -n 1 | cut -d= -f2-)

          # ---------- pass 2: rip + encode, quietly ----------
          # set -m: abcde gets its own process group, so Ctrl-C can stop
          # cd-paranoia and the encoders too, not just abcde
          set -m
          abcde "''${conf_args[@]}" -N -a read,encode,tag,move,clean "$@" > "$log" 2>&1 &
          pid=$!
          trap 'kill -- -"$pid" 2>/dev/null; echo; echo "rip-cd: stopped, log: $log" >&2; exit 130' INT TERM

          last=""
          count() { local n; n=$(grep -cE "^$1" "$status" 2>/dev/null); echo "''${n:-0}"; }

          draw() {   # $1 = optional text instead of the album name
              [[ -f $status ]] || return 0   # abcde removes its work folder when done
              local r e t line
              r=$(count 'readtrack-[0-9]+$')
              e=$(count 'encodetrack-[a-z0-9]+-')   # per format; skip the per-track summary line
              t=$(count 'tagtrack-[a-z0-9]+-')
              local all='?'
              [[ $tracks != '?' ]] && all=$(( tracks * ''${#fmts[@]} ))
              printf -v line 'rip %s/%s | encode %s/%s | tag %s/%s | %s' \
                  "$r" "$tracks" "$e" "$all" "$t" "$all" "''${1:-$album}"
              [[ $line == "$last" ]] && return
              last=$line
              show "$line"
          }

          start=$SECONDS
          while kill -0 "$pid" 2>/dev/null; do draw; sleep 0.5; done
          wait "$pid"; rc=$?
          draw

          if (( rc != 0 )) || grep -q '^\[ERROR\]' "$log"; then
              [[ -t 1 ]] && echo
              echo "rip-cd: abcde reported problems (exit $rc). Last lines of $log:" >&2
              tail -n 15 "$log" >&2
              [[ -d $workdir ]] && echo "rip-cd: work folder kept at $workdir; fix and rerun to resume" >&2
              exit 1
          fi
          elapsed=$(( SECONDS - start ))
          all='?'; [[ $tracks != '?' ]] && all=$(( tracks * ''${#fmts[@]} ))
          printf -v done_line 'rip %s/%s | encode %s/%s | tag %s/%s | done in %dm%ds' \
              "$tracks" "$tracks" "$all" "$all" "$all" "$all" $(( elapsed / 60 )) $(( elapsed % 60 ))
          show "$done_line"; [[ -t 1 ]] && echo
          echo "-> $staging/  (log: $log)"
        '';
      };

      # Purchased WAVs -> FLAC + MP3 in ~/Music/staging, with a progress bar.
      encode-wav = pkgs.writeShellApplication {
        name = "encode-wav";
        runtimeInputs = with pkgs; [flac lame coreutils ncurses];
        bashOptions = ["nounset" "pipefail"];
        text = ''
          # encode-wav: turn a folder of purchased WAVs into FLAC + MP3 for Picard.
          # Usage is in usage() below. The WAVs are left alone.

          # Encoder settings and the staging root come from FLACOPTS/LAMEOPTS/OUTPUTDIR
          # in ~/.abcde.conf (or $ABCDE_CONF), so CD rips and WAV encodes stay the same.
          ${common}
          read -ra flacopts <<< "$(read_conf FLACOPTS '-s -e -V -5')"
          read -ra lameopts <<< "$(read_conf LAMEOPTS '-V 0 -h --silent')"

          out_root=$(read_conf OUTPUTDIR "$HOME/Music/staging")
          jobs_max=$(nproc 2>/dev/null || echo 2)
          formats="flac,mp3"

          usage() {
              cat <<'USAGE'
          encode-wav [-o DIR] [-j JOBS] [-f flac,mp3] [SOURCE_DIR]

            SOURCE_DIR  folder with .wav files (default: current folder)
            -o DIR      staging root (default: OUTPUTDIR from ~/.abcde.conf)
            -j JOBS     parallel encoders (default: number of CPUs)
            -f LIST     formats to make (default: flac,mp3)

          Output goes to DIR/<name of SOURCE_DIR>/.
          USAGE
              exit "''${1:-0}"
          }

          while getopts ":o:j:f:h" opt; do
              case $opt in
                  o) out_root=$OPTARG ;;
                  j) jobs_max=$OPTARG ;;
                  f) formats=$OPTARG ;;
                  h) usage 0 ;;
                  *) usage 1 ;;
              esac
          done
          shift $((OPTIND - 1))

          [[ $jobs_max =~ ^[1-9][0-9]*$ ]] || { echo "encode-wav: -j needs a positive number" >&2; exit 1; }

          src=$(cd "''${1:-.}" && pwd) || exit 1
          dest="$out_root/$(basename "$src")"
          logdir="$out_root/.logs"
          log="$logdir/encode-wav-$(date +%Y%m%d-%H%M%S).log"

          IFS=, read -ra fmts <<< "$formats"
          for f in "''${fmts[@]}"; do
              case $f in
                  flac|mp3) ;;
                  *)    echo "encode-wav: unknown format '$f' (use flac and/or mp3)" >&2; exit 1 ;;
              esac
          done

          shopt -s nullglob nocaseglob
          wavs=("$src"/*.wav)
          shopt -u nocaseglob
          (( ''${#wavs[@]} )) || { echo "encode-wav: no .wav files in $src" >&2; exit 1; }

          mkdir -p "$dest" "$logdir"

          encode() {   # $1 = format, $2 = wav file
              local out
              out="$dest/$(basename "''${2%.*}")"
              case $1 in
                  flac) flac "''${flacopts[@]}" -f -o "$out.flac" "$2" ;;
                  mp3)  lame "''${lameopts[@]}" "$2" "$out.mp3" ;;
              esac
          }

          # ---------- one-line progress ----------
          total=$(( ''${#wavs[@]} * ''${#fmts[@]} ))
          launched=0 reaped=0 fails=0
          start=$SECONDS
          declare -A label

          draw() {   # $1 = what just finished
              local pct=$(( reaped * 100 / total )) w=20 bar
              local fill=$(( reaped * w / total ))
              printf -v bar '%*s' "$fill" '''; bar=''${bar// /#}
              printf -v bar '%-*s' "$w" "$bar"; bar=''${bar// /.}
              local line
              printf -v line '[%s] %3d%%  %d/%d  %s%s' "$bar" "$pct" "$reaped" "$total" \
                  "$( (( fails )) && echo "$fails FAILED  ")" "$1"
              show "$line"
          }

          reap() {
              local pid rc
              wait -n -p pid; rc=$?
              [[ -n ''${pid:-} ]] || return 0
              reaped=$(( reaped + 1 ))
              if (( rc != 0 )); then
                  fails=$(( fails + 1 ))
                  echo "FAILED (exit $rc): ''${label[$pid]}" >> "$log"
              fi
              draw "''${label[$pid]}"
              unset "label[$pid]"
          }

          # set -m: each encode gets its own process group, so the trap stops flac/lame too
          set -m
          # shellcheck disable=SC2329 # called by the trap below
          stop() {
              local p
              for p in $(jobs -p); do kill -- -"$p" 2>/dev/null; done
              echo; echo "encode-wav: stopped" >&2; exit 130
          }
          trap stop INT TERM

          draw "starting (''${#wavs[@]} files, $jobs_max jobs)"
          for w in "''${wavs[@]}"; do
              for f in "''${fmts[@]}"; do
                  while (( launched - reaped >= jobs_max )); do reap; done
                  encode "$f" "$w" 2>> "$log" &
                  label[$!]="$f  $(basename "$w")"
                  launched=$(( launched + 1 ))
              done
          done
          while (( reaped < launched )); do reap; done

          elapsed=$(( SECONDS - start ))
          draw "done in $(( elapsed / 60 ))m$(( elapsed % 60 ))s"
          [[ -t 1 ]] && echo
          echo "-> $dest"
          if (( fails )); then
              echo "encode-wav: $fails encode(s) failed, see $log" >&2
              exit 1
          fi
          [[ -s $log ]] || rm -f "$log"
          rmdir "$logdir" 2>/dev/null
          exit 0
        '';
      };
      # ReplayGain 2.0 for library albums that have none yet (rsgain easy).
      music-gain = pkgs.writeShellApplication {
        name = "music-gain";
        runtimeInputs = with pkgs; [rsgain coreutils];
        text = ''
          # music-gain: add ReplayGain 2.0 tags to library albums that don't have them yet.
          # Usage is in usage() below.
          #
          # Runs `rsgain easy` (-18 LUFS, track + album gain, one album per folder).
          # Run it after Picard has moved files into the library, never on staging:
          # encode-wav puts FLAC and MP3 in one staging folder, which spoils album gain.

          usage() {
              cat <<'USAGE'
          music-gain [-f] [DIR...]

            DIR   folders to scan (default: ~/Music/FLAC and ~/Music/MP3)
            -f    rescan everything, even albums that already have tags
          USAGE
              exit "''${1:-0}"
          }

          skip=(--skip-existing)
          while getopts ":fh" opt; do
              case $opt in
                  f) skip=() ;;
                  h) usage 0 ;;
                  *) usage 1 ;;
              esac
          done
          shift $((OPTIND - 1))

          dirs=("$@")
          if (( ''${#dirs[@]} == 0 )); then
              for d in "$HOME/Music/FLAC" "$HOME/Music/MP3"; do
                  if [[ -d $d ]]; then dirs+=("$d"); fi
              done
          fi
          (( ''${#dirs[@]} )) || { echo "music-gain: nothing to scan (no ~/Music/FLAC or ~/Music/MP3)" >&2; exit 1; }

          rc=0
          for d in "''${dirs[@]}"; do
              if [[ $(realpath -m "$d") == "$(realpath -m "$HOME/Music/staging")"* ]]; then
                  echo "music-gain: skipping $d (staging; run after Picard)" >&2
                  continue
              fi
              echo "== $d"
              rsgain easy "''${skip[@]}" --multithread MAX "$d" || rc=1
          done
          exit "$rc"
        '';
      };
    in {
      environment.systemPackages = with pkgs; [
        abcde
        cddiscid
        exiftool
        ffmpeg-full
        flac
        icu.dev # uconv, for mungefilename in ~/.abcde.conf
        id3v2
        imagemagick
        lame
        libcdio-paranoia
        rsgain
        rip-cd
        encode-wav
        music-gain
      ];
    };
  };
}
