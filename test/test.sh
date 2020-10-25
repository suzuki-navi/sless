
cd $(dirname $0)
mkdir -p actual

result=0

for f in $(ls input); do
    echo $f
    cat input/$f | ../bin/sless -v > actual/$f.txt.1 2> actual/$f.txt
    cat actual/$f.txt.1 >> actual/$f.txt
    rm actual/$f.txt.1
    if [ ! -e expected/$f.txt ]; then
        touch expected/$f.txt
    fi
    if ! diff -u expected/$f.txt actual/$f.txt; then
        result=1
    fi
done

exit $result

