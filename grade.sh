#!/bin/bash
set -euo pipefail

STAGE_DIR="${1:-.}"

echo "== Environment =="
python3 --version
g++ --version
javac -version
java -version

echo ""
echo "== Grading Directory: $STAGE_DIR =="

shopt -s nullglob

fail=0
total=0
passed=0

for prob_dir in "$STAGE_DIR"/solutions/*/; do
    prob_dir_clean="${prob_dir%/}"
    prob_folder_name=$(basename "$prob_dir_clean")
    prob_num=$(echo "$prob_folder_name" | grep -oE '[0-9]+')

    echo ""
    echo "---- Problem: $prob_folder_name ----"

    test_dir="$STAGE_DIR/tests/problem$prob_num"
    if [[ ! -d "$test_dir" ]]; then
        echo "ERROR: Missing test directory: $test_dir"
        fail=1
        continue
    fi

    # Find submission files
    py_files=("$prob_dir"*.py)
    java_files=("$prob_dir"*.java)
    cpp_files=("$prob_dir"*.cpp "$prob_dir"*.cc "$prob_dir"*.cxx)

    sub_file=""
    if [ ${#py_files[@]} -gt 0 ]; then
        sub_file="${py_files[0]}"
    elif [ ${#java_files[@]} -gt 0 ]; then
        sub_file="${java_files[0]}"
    elif [ ${#cpp_files[@]} -gt 0 ]; then
        sub_file="${cpp_files[0]}"
    else
        echo "ERROR: No submission found in $prob_dir"
        fail=1
        continue
    fi

    echo "Using submission: $sub_file"

    inputs=("$test_dir"/input*.txt)
    if [ ${#inputs[@]} -eq 0 ]; then
        echo "ERROR: No inputs found in $test_dir"
        fail=1
        continue
    fi

    for in_file in "${inputs[@]}"; do
        base=$(basename "$in_file")
        suffix="${base#input}"
        exp_file="$test_dir/expected$suffix"

        if [[ ! -f "$exp_file" ]]; then
            echo "ERROR: Missing expected file: $exp_file"
            fail=1
            continue
        fi

        total=$((total+1))
        echo -n "Test $base: "

        if python3 runner.py --file "$sub_file" --stdin "$in_file" --expected "$exp_file"; then
            passed=$((passed+1))
            echo "PASS"
        else
            echo "FAIL"
            fail=1
        fi
    done
done

echo ""
echo "=============================="
echo "Summary: Passed $passed / $total tests"
echo "=============================="

if [ $fail -ne 0 ]; then
    echo "OVERALL RESULT: FAIL"
    exit 1
else
    echo "OVERALL RESULT: PASS"
    exit 0
fi
