__check_system(){
    local PG_VERSION

    command -v pg_ctl &> /dev/null || { echo "Error: Required command 'pg_ctl' not found" >&2;return 1; }

    PG_VERSION=$(pg_ctl --version | awk '{print int($3)}')

    command -v initdb &> /dev/null || { printf "'initdb' is not in PATH.\nAdd /usr/lib/postgresql/$PG_VERSION/bin to PATH." >&2;return 1; }

    echo $PG_VERSION
}

__init(){
    local PG_CTL_OUT_FILE=$(mktemp /tmp/pg_ctl_status.XXXXXX)
    pg_ctl status -D $PG_DIR > $PG_CTL_OUT_FILE 2>&1
    local STATUS=$?
    case $STATUS in
        0)
            PG_PID=$(head -n 1 $PG_CTL_OUT_FILE | awk '{print $NF}' | tr -cd '[0-9]')
            echo "A postgres instance is already running with datadir $PG_DIR."
            echo "PID: $PG_PID"
            return 1
            ;;
        3)
            echo "$PG_DIR is already initialized. Server is stopped."
            return 1
            ;;
        4)
            initdb --nosync -D $PG_DIR -E UNICODE -A trust > $PG_DIR/initdb.out
            [ $? -ne 0 ] && { cat $PG_DIR/initdb.out; return 1; }
            return
            ;;
        *)
            cat $PG_CTL_OUT_FILE
            return 1
            ;;
    esac
}

pg_temp(){
    
    local PG_VERSION=$(__check_system)
    local PG_DIR="/tmp/postgres"
    

    [ $? -ne 0 ] && return;

    case ${1:-start} in
        init)
            __init $PG_VERSION
            ;;
        start)
            echo "Starting /tmp based instance of PG $PG_VERSION"
            ;;
        status)
            echo "command is status"
            ;;
        stop)
            echo "command is stop"
            ;;
        reinit)
            echo "command is reinit"
            ;;
        *)
            echo "command is unkown"
            ;;
    esac
}