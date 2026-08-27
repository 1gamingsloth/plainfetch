#!/bin/sh

# As this script is meant to work with POSIX sh you can replace /bin/sh with /bin/dash for example.

tmp=${TMPDIR:-/tmp}/fetch.$$
trap 'rm -f "$tmp"' EXIT HUP INT TERM

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cat "$script_dir/logo" >"$tmp"

# System information
os=Unknown
if [ -r /etc/os-release ]; then
    . /etc/os-release
    os=${PRETTY_NAME:-${NAME:-Unknown}}
fi

kernel=$(uname -r)
arch=$(uname -m)
hostname=$(hostname)
shell=${SHELL:-Unknown}
terminal=${TERM:-Unknown}

# CPU
cpu=Unknown
if [ -r /proc/cpuinfo ]; then
    cpu=$(awk -F ': ' '/^model name/ {print $2; exit}' /proc/cpuinfo)
fi

# memory
memory=Unknown
if [ -r /proc/meminfo ]; then
    memory=$(awk '
        /^MemTotal:/     { total=$2 }
        /^MemAvailable:/ { avail=$2 }
        END {
            used=(total-avail)/1024
            total=total/1024
            printf "%.0f MiB / %.0f MiB", used, total
        }
    ' /proc/meminfo)
fi

# uptime
uptime=Unknown
if [ -r /proc/uptime ]; then
    uptime=$(awk '
        {
            s=int($1)
            d=int(s/86400)
            h=int((s%86400)/3600)
            m=int((s%3600)/60)

            if (d > 0)
                printf "%dd %dh %dm", d, h, m
            else if (h > 0)
                printf "%dh %dm", h, m
            else
                printf "%dm", m
        }
    ' /proc/uptime)
fi

# draw lines and stuff
width=80
line=$(printf '%*s' $((width - 2)) '' | tr ' ' '-')

printf '+%s+\n' "$line"

i=1

while [ "$i" -le 9 ]; do
    left=""

    if [ "$i" -le 4 ]; then
        IFS= read -r left
    fi

    case $i in
        1) right="OS       $os" ;;
        2) right="Host     $hostname" ;;
        3) right="Kernel   $kernel" ;;
        4) right="Arch     $arch" ;;
        5) right="Uptime   $uptime" ;;
        6) right="Shell    $shell" ;;
        7) right="Term     $terminal" ;;
        8) right="CPU      $cpu" ;;
        9) right="Memory   $memory" ;;
    esac

    content=$(printf '%-20s  %s' "$left" "$right")

    printf '│ %-*s │\n' "$((width - 4))" "$content"

    i=$((i + 1))
done < "$tmp"

printf '+%s+\n' "$line"
