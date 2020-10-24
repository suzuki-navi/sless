
cd $(dirname $0)
mkdir -p actual

result=0

for f in $(ls input); do
    echo $f
    cat input/$f | ../bin/sless -v > actual/$f.txt
    if [ ! -e expected/$f.txt ]; then
        touch expected/$f.txt
    fi
    if ! diff -u expected/$f.txt actual/$f.txt; then
        result=1
    fi
done

exit $result

