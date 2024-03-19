set -x

echo "Bytecode"
BYTECODE=$(forge inspect MEMERC20 bytecode)
echo "types"
TYPES=$(forge inspect MEMERC20 abi \
    | jq -r '.[] | select(.type == "constructor") | .inputs | map(.type) | join(",")')
echo "args"
ARGS=$(cast abi-encode "constructor($TYPES)" "world" "hello")

echo "calldata"
CALLDATA=$(cast --concat-hex "$BYTECODE" "$ARGS")

set +x
