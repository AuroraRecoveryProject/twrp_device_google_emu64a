LOCAL_DIR=$(cd "$(dirname "$0")"; pwd)
cd "$LOCAL_DIR"
rsync -av --delete --exclude '.git' --exclude '.DS_Store' . laurie@192.168.31.206:/home/laurie/twrp/device/google/emu64a/