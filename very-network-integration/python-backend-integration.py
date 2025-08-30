#!/usr/bin/env python3
"""
Python Backend Integration for StrideonScores
Connects to deployed contracts on local Hardhat network
"""

import json
import requests
from web3 import Web3
from eth_account import Account
import time

class StrideonScoresBackend:
    def __init__(self):
        # Network configuration
        self.rpc_url = "http://192.168.31.172:8545"
        self.chain_id = 1337
        
        # Contract addresses (from deployment)
        self.STRIDEON_SCORES_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
        self.VERY_TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
        
        # Test account (for backend operations)
        self.test_private_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
        self.test_address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        
        # Initialize Web3
        self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))
        
        # Load contract ABIs
        self.load_contract_abis()
        
        # Initialize contracts
        self.strideon_scores = self.w3.eth.contract(
            address=self.STRIDEON_SCORES_ADDRESS,
            abi=self.strideon_scores_abi
        )
        
        self.very_token = self.w3.eth.contract(
            address=self.VERY_TOKEN_ADDRESS,
            abi=self.very_token_abi
        )
        
        # Set up account
        self.account = Account.from_key(self.test_private_key)
        
    def load_contract_abis(self):
        """Load contract ABIs from files"""
        try:
            with open('strideon-scores-abi.json', 'r') as f:
                self.strideon_scores_abi = json.load(f)
            with open('mock-erc20-abi.json', 'r') as f:
                self.very_token_abi = json.load(f)
        except FileNotFoundError:
            print("ABI files not found. Using minimal ABIs...")
            # Fallback minimal ABIs
            self.strideon_scores_abi = [
                {
                    "inputs": [{"internalType": "address", "name": "player", "type": "address"}],
                    "name": "getPlayerScore",
                    "outputs": [{"internalType": "uint256", "name": "score", "type": "uint256"}],
                    "stateMutability": "view",
                    "type": "function"
                },
                {
                    "inputs": [{"internalType": "uint256", "name": "count", "type": "uint256"}],
                    "name": "getLeaderboard",
                    "outputs": [
                        {"internalType": "address[]", "name": "addresses", "type": "address[]"},
                        {"internalType": "uint256[]", "name": "scores", "type": "uint256[]"}
                    ],
                    "stateMutability": "view",
                    "type": "function"
                },
                {
                    "inputs": [{"internalType": "uint256", "name": "powerUpType", "type": "uint256"}, {"internalType": "uint256", "name": "maxPrice", "type": "uint256"}],
                    "name": "purchasePowerUp",
                    "outputs": [],
                    "stateMutability": "nonpayable",
                    "type": "function"
                },
                {
                    "inputs": [],
                    "name": "claimPlayerScore",
                    "outputs": [],
                    "stateMutability": "nonpayable",
                    "type": "function"
                }
            ]
            
            self.very_token_abi = [
                {
                    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
                    "name": "balanceOf",
                    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
                    "stateMutability": "view",
                    "type": "function"
                }
            ]
    
    def check_connection(self):
        """Check if connected to the network"""
        try:
            latest_block = self.w3.eth.block_number
            print(f"✅ Connected to network. Latest block: {latest_block}")
            return True
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def get_account_balance(self, address=None):
        """Get ETH balance of an account"""
        if address is None:
            address = self.test_address
        
        try:
            balance = self.w3.eth.get_balance(address)
            balance_eth = self.w3.from_wei(balance, 'ether')
            print(f"💰 Balance of {address}: {balance_eth} ETH")
            return balance_eth
        except Exception as e:
            print(f"❌ Failed to get balance: {e}")
            return 0
    
    def get_player_score(self, player_address):
        """Get player score from contract"""
        try:
            score = self.strideon_scores.functions.getPlayerScore(player_address).call()
            print(f"📊 Player {player_address} score: {score}")
            return score
        except Exception as e:
            print(f"❌ Failed to get player score: {e}")
            return 0
    
    def get_leaderboard(self, count=10):
        """Get leaderboard from contract"""
        try:
            addresses, scores = self.strideon_scores.functions.getLeaderboard(count).call()
            leaderboard = []
            for i, (addr, score) in enumerate(zip(addresses, scores)):
                leaderboard.append({
                    'rank': i + 1,
                    'address': addr,
                    'score': score
                })
            print(f"🏆 Leaderboard: {leaderboard}")
            return leaderboard
        except Exception as e:
            print(f"❌ Failed to get leaderboard: {e}")
            return []
    
    def get_token_balance(self, address):
        """Get VERY token balance"""
        try:
            balance = self.very_token.functions.balanceOf(address).call()
            balance_formatted = self.w3.from_wei(balance, 'ether')
            print(f"🪙 VERY Token balance of {address}: {balance_formatted}")
            return balance_formatted
        except Exception as e:
            print(f"❌ Failed to get token balance: {e}")
            return 0
    
    def purchase_power_up(self, power_up_type, max_price_eth):
        """Purchase a power-up (backend operation)"""
        try:
            max_price_wei = self.w3.to_wei(max_price_eth, 'ether')
            
            # Build transaction
            transaction = self.strideon_scores.functions.purchasePowerUp(
                power_up_type, 
                max_price_wei
            ).build_transaction({
                'from': self.test_address,
                'gas': 200000,
                'gasPrice': self.w3.eth.gas_price,
                'nonce': self.w3.eth.get_transaction_count(self.test_address),
            })
            
            # Sign and send transaction
            signed_txn = self.w3.eth.account.sign_transaction(transaction, self.test_private_key)
            tx_hash = self.w3.eth.send_raw_transaction(signed_txn.rawTransaction)
            
            # Wait for confirmation
            tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
            
            print(f"✅ Power-up purchased! Transaction: {tx_hash.hex()}")
            return tx_hash.hex()
            
        except Exception as e:
            print(f"❌ Failed to purchase power-up: {e}")
            return None
    
    def claim_player_score(self, player_address):
        """Claim player score (backend operation)"""
        try:
            # Build transaction
            transaction = self.strideon_scores.functions.claimPlayerScore().build_transaction({
                'from': player_address,
                'gas': 200000,
                'gasPrice': self.w3.eth.gas_price,
                'nonce': self.w3.eth.get_transaction_count(player_address),
            })
            
            # Sign and send transaction
            signed_txn = self.w3.eth.account.sign_transaction(transaction, self.test_private_key)
            tx_hash = self.w3.eth.send_raw_transaction(signed_txn.rawTransaction)
            
            # Wait for confirmation
            tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
            
            print(f"✅ Score claimed! Transaction: {tx_hash.hex()}")
            return tx_hash.hex()
            
        except Exception as e:
            print(f"❌ Failed to claim score: {e}")
            return None
    
    def create_mobile_api_endpoints(self):
        """Example API endpoints for mobile app"""
        from flask import Flask, request, jsonify
        
        app = Flask(__name__)
        
        @app.route('/api/player/score/<address>', methods=['GET'])
        def get_player_score_api(address):
            score = self.get_player_score(address)
            return jsonify({'address': address, 'score': score})
        
        @app.route('/api/leaderboard', methods=['GET'])
        def get_leaderboard_api():
            count = request.args.get('count', 10, type=int)
            leaderboard = self.get_leaderboard(count)
            return jsonify({'leaderboard': leaderboard})
        
        @app.route('/api/token/balance/<address>', methods=['GET'])
        def get_token_balance_api(address):
            balance = self.get_token_balance(address)
            return jsonify({'address': address, 'balance': str(balance)})
        
        @app.route('/api/powerup/purchase', methods=['POST'])
        def purchase_powerup_api():
            data = request.json
            power_up_type = data.get('powerUpType')
            max_price = data.get('maxPrice')
            player_address = data.get('playerAddress')
            
            tx_hash = self.purchase_power_up(power_up_type, max_price)
            return jsonify({'success': True, 'transactionHash': tx_hash})
        
        return app

# Example usage
if __name__ == "__main__":
    print("🚀 Initializing StrideonScores Backend...")
    
    backend = StrideonScoresBackend()
    
    # Check connection
    if not backend.check_connection():
        print("❌ Cannot connect to network. Make sure Hardhat node is running.")
        exit(1)
    
    print("\n📋 Testing Backend Functions:")
    print("=" * 50)
    
    # Test basic functions
    backend.get_account_balance()
    backend.get_player_score(backend.test_address)
    backend.get_leaderboard(5)
    backend.get_token_balance(backend.test_address)
    
    print("\n🎮 Backend ready for mobile integration!")
    print("📱 Use the API endpoints to connect your mobile app.")
    print("🔗 Network: http://192.168.31.172:8545")
    print("📋 Contract Addresses:")
    print(f"   - StrideonScores: {backend.STRIDEON_SCORES_ADDRESS}")
    print(f"   - VERY Token: {backend.VERY_TOKEN_ADDRESS}")
