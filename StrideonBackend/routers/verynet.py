from typing import List, Dict, Any
import os
from fastapi import APIRouter, HTTPException, Query, Path

try:
    from web3 import Web3
except Exception:  # pragma: no cover
    Web3 = None  # type: ignore

router = APIRouter(prefix="/verynet", tags=["verynet"]) 

# --- Config ---
VERY_RPC_URL = os.environ.get("VERY_RPC_URL", "http://127.0.0.1:8545")
VERY_CHAIN_ID = int(os.environ.get("VERY_CHAIN_ID", "1337"))
# Default address matches Hardhat sample from very-network-integration
VERY_CONTRACT_ADDR = os.environ.get(
    "VERY_CONTRACT_ADDR",
    "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
)

# Minimal ABI for read methods to avoid external file dependency
STRIDEON_SCORES_ABI = [
    {
        "inputs": [{"internalType": "address", "name": "player", "type": "address"}],
        "name": "getPlayerScore",
        "outputs": [{"internalType": "uint256", "name": "score", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function",
    },
    {
        "inputs": [{"internalType": "uint256", "name": "count", "type": "uint256"}],
        "name": "getLeaderboard",
        "outputs": [
            {"internalType": "address[]", "name": "addresses", "type": "address[]"},
            {"internalType": "uint256[]", "name": "scores", "type": "uint256[]"},
        ],
        "stateMutability": "view",
        "type": "function",
    },
]

_w3 = None
_contract = None


def _ensure_web3():
    global _w3, _contract
    if Web3 is None:
        raise HTTPException(500, "web3 is not installed on the server")
    if _w3 is None:
        _w3 = Web3(Web3.HTTPProvider(VERY_RPC_URL))
    if _contract is None:
        try:
            _contract = _w3.eth.contract(address=VERY_CONTRACT_ADDR, abi=STRIDEON_SCORES_ABI)
        except Exception as e:
            raise HTTPException(500, f"Failed to init contract: {e}")
    return _w3, _contract


@router.get("/health")
async def verinet_health() -> Dict[str, Any]:
    try:
        w3, _ = _ensure_web3()
        latest = w3.eth.block_number
        return {
            "ok": True,
            "rpc": VERY_RPC_URL,
            "chain_id": VERY_CHAIN_ID,
            "latest_block": int(latest),
            "contract": VERY_CONTRACT_ADDR,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Very Network connection error: {e}")


@router.get("/leaderboard")
async def verinet_leaderboard(count: int = Query(default=10, ge=1, le=100)) -> List[Dict[str, Any]]:
    try:
        w3, contract = _ensure_web3()
        addrs, scores = contract.functions.getLeaderboard(int(count)).call()
        out: List[Dict[str, Any]] = []
        for i, (addr, score) in enumerate(zip(addrs, scores)):
            # web3 returns HexBytes for addresses sometimes; normalize to checksum
            try:
                addr_str = w3.to_checksum_address(addr)
            except Exception:
                addr_str = str(addr)
            out.append({
                "rank": i + 1,
                "address": addr_str,
                "score": int(score),
            })
        return out
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Failed to read leaderboard: {e}")


@router.get("/score/{address}")
async def verinet_score(address: str = Path(..., description="EVM address")) -> Dict[str, Any]:
    try:
        w3, contract = _ensure_web3()
        # Validate/normalize address but allow passthrough for local
        try:
            addr = w3.to_checksum_address(address)
        except Exception:
            raise HTTPException(400, "Invalid address format")
        score = contract.functions.getPlayerScore(addr).call()
        return {"address": addr, "score": int(score)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Failed to read score: {e}")
