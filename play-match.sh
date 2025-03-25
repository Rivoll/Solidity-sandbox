#!/bin/bash

set -e

# === CONFIG ===
RPC_URL=http://127.0.0.1:8545
CONTRACT="0x457cCf29090fe5A24c19c1bc95F492168C0EaFdb" # 👈 Replace this

PLAYER1_ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PLAYER1_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

PLAYER2_ADDR=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
PLAYER2_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

BET=100 # 1 ETH in wei
SECRET="secret123"

# === INPUT ===
# Usage: ./test-match.sh rock scissors
P1_CHOICE=$1
P2_CHOICE=$2

# === ENUM MAPPING ===
function to_enum() {
  case "$1" in
    rock) echo 0 ;;
    papper) echo 1 ;;
    scissors) echo 2 ;;
    *) echo "❌ Invalid choice: $1"; exit 1 ;;
  esac
}

P1_ENUM=$(to_enum "$P1_CHOICE")
P2_ENUM=$(to_enum "$P2_CHOICE")

echo "🎮 P1 = $P1_CHOICE [$P1_ENUM], P2 = $P2_CHOICE [$P2_ENUM]"

# === 1. COMMIT: Player 1 sends hashed commitment
COMMIT_HASH=$(cast keccak $(echo "$P1_ENUM$SECRET"))
echo "🔒 P1 Commit hash: $COMMIT_HASH"

cast send $CONTRACT "chooseYourAction(uint8,string)" $P1_ENUM "$SECRET" \
  --private-key $PLAYER1_PK --value $BET --rpc-url $RPC_URL --quiet

# === 2. Player 2 submits their move + bet
cast send $CONTRACT "chooseYourAction(uint8,string)" $P2_ENUM "noop" \
  --private-key $PLAYER2_PK --value $BET --rpc-url $RPC_URL --quiet

# === 3. Player 1 reveals move
cast send $CONTRACT "chooseYourAction(uint8,string)" $P1_ENUM "$SECRET" \
  --private-key $PLAYER1_PK --rpc-url $RPC_URL --quiet

# === 4. Print results
echo "🏆 Last winner:"
cast call $CONTRACT "lastWinner()(address)" --rpc-url $RPC_URL

echo "📊 Player 1 stats:"
cast call $CONTRACT "getPlayerStats(address)(address,uint256,uint256,uint256,int256,uint256,uint8)" $PLAYER1_ADDR --rpc-url $RPC_URL

echo "📊 Player 2 stats:"
cast call $CONTRACT "getPlayerStats(address)(address,uint256,uint256,uint256,int256,uint256,uint8)" $PLAYER2_ADDR --rpc-url $RPC_URL

echo "🏦 House balance (ETH):"
cast call $CONTRACT "houseBalance()(uint256)" --rpc-url $RPC_URL 
