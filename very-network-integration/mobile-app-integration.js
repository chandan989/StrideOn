// Mobile App Integration for StrideonScores
// Works with React Native, Flutter, or any mobile framework

class StrideonScoresMobile {
    constructor() {
        // Network configuration
        this.networkConfig = {
            rpcUrl: 'http://192.168.31.172:8545',
            chainId: 1337,
            networkName: 'Local Hardhat'
        };
        
        // Contract addresses (from deployment)
        this.contractAddresses = {
            strideonScores: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
            veryToken: '0x5FbDB2315678afecb367f032d93F642f64180aa3'
        };
        
        // API endpoints (for backend communication)
        this.apiBaseUrl = 'http://your-backend-server:5000/api';
        
        // User wallet info
        this.userAddress = null;
        this.userPrivateKey = null;
    }

    // ===== WALLET CONNECTION =====
    
    async connectWallet(privateKey) {
        try {
            this.userPrivateKey = privateKey;
            // In real app, you'd use a secure wallet connection
            // For demo, we'll use the test account
            this.userAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
            
            console.log('✅ Wallet connected:', this.userAddress);
            return { success: true, address: this.userAddress };
        } catch (error) {
            console.error('❌ Wallet connection failed:', error);
            return { success: false, error: error.message };
        }
    }

    // ===== BACKEND API CALLS =====
    
    async callBackendAPI(endpoint, method = 'GET', data = null) {
        try {
            const url = `${this.apiBaseUrl}${endpoint}`;
            const options = {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                }
            };
            
            if (data) {
                options.body = JSON.stringify(data);
            }
            
            const response = await fetch(url, options);
            const result = await response.json();
            
            return { success: true, data: result };
        } catch (error) {
            console.error('❌ API call failed:', error);
            return { success: false, error: error.message };
        }
    }

    // ===== GAME FUNCTIONS =====
    
    async getPlayerScore(address = null) {
        const playerAddress = address || this.userAddress;
        if (!playerAddress) {
            return { success: false, error: 'No wallet connected' };
        }
        
        const result = await this.callBackendAPI(`/player/score/${playerAddress}`);
        return result;
    }
    
    async getLeaderboard(count = 10) {
        const result = await this.callBackendAPI(`/leaderboard?count=${count}`);
        return result;
    }
    
    async getTokenBalance(address = null) {
        const playerAddress = address || this.userAddress;
        if (!playerAddress) {
            return { success: false, error: 'No wallet connected' };
        }
        
        const result = await this.callBackendAPI(`/token/balance/${playerAddress}`);
        return result;
    }
    
    async purchasePowerUp(powerUpType, maxPrice) {
        if (!this.userAddress) {
            return { success: false, error: 'No wallet connected' };
        }
        
        const data = {
            powerUpType: powerUpType,
            maxPrice: maxPrice,
            playerAddress: this.userAddress
        };
        
        const result = await this.callBackendAPI('/powerup/purchase', 'POST', data);
        return result;
    }
    
    async claimPlayerScore() {
        if (!this.userAddress) {
            return { success: false, error: 'No wallet connected' };
        }
        
        const result = await this.callBackendAPI('/player/claim', 'POST', {
            playerAddress: this.userAddress
        });
        return result;
    }

    // ===== DIRECT BLOCKCHAIN CALLS (Alternative) =====
    
    async callContractDirectly(contractAddress, abi, method, params = []) {
        try {
            // This would use Web3.js or ethers.js in your mobile app
            // For React Native, you'd use react-native-web3 or similar
            // For Flutter, you'd use web3dart
            
            const web3 = new Web3(this.networkConfig.rpcUrl);
            const contract = new web3.eth.Contract(abi, contractAddress);
            
            const result = await contract.methods[method](...params).call();
            return { success: true, data: result };
        } catch (error) {
            console.error('❌ Direct contract call failed:', error);
            return { success: false, error: error.message };
        }
    }
}

// ===== REACT NATIVE EXAMPLE =====

import React, { useState, useEffect } from 'react';
import { View, Text, Button, TextInput, Alert } from 'react-native';

const StrideonScoresApp = () => {
    const [mobileApp, setMobileApp] = useState(null);
    const [playerScore, setPlayerScore] = useState(0);
    const [leaderboard, setLeaderboard] = useState([]);
    const [tokenBalance, setTokenBalance] = useState(0);
    const [isConnected, setIsConnected] = useState(false);

    useEffect(() => {
        // Initialize the mobile app
        const app = new StrideonScoresMobile();
        setMobileApp(app);
    }, []);

    const connectWallet = async () => {
        if (!mobileApp) return;
        
        // In real app, you'd get this from secure storage or user input
        const testPrivateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
        
        const result = await mobileApp.connectWallet(testPrivateKey);
        if (result.success) {
            setIsConnected(true);
            Alert.alert('Success', 'Wallet connected!');
        } else {
            Alert.alert('Error', result.error);
        }
    };

    const getPlayerScore = async () => {
        if (!mobileApp || !isConnected) return;
        
        const result = await mobileApp.getPlayerScore();
        if (result.success) {
            setPlayerScore(result.data.score);
        } else {
            Alert.alert('Error', result.error);
        }
    };

    const getLeaderboard = async () => {
        if (!mobileApp) return;
        
        const result = await mobileApp.getLeaderboard(5);
        if (result.success) {
            setLeaderboard(result.data.leaderboard);
        } else {
            Alert.alert('Error', result.error);
        }
    };

    const purchasePowerUp = async () => {
        if (!mobileApp || !isConnected) return;
        
        const result = await mobileApp.purchasePowerUp(1, 0.01); // Shield, 0.01 ETH
        if (result.success) {
            Alert.alert('Success', 'Power-up purchased!');
        } else {
            Alert.alert('Error', result.error);
        }
    };

    return (
        <View style={{ flex: 1, padding: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: 'bold', marginBottom: 20 }}>
                🏃‍♂️ StrideonScores
            </Text>
            
            {!isConnected ? (
                <Button title="Connect Wallet" onPress={connectWallet} />
            ) : (
                <View>
                    <Text>✅ Wallet Connected</Text>
                    <Button title="Get Player Score" onPress={getPlayerScore} />
                    <Button title="Get Leaderboard" onPress={getLeaderboard} />
                    <Button title="Buy Shield Power-up" onPress={purchasePowerUp} />
                    
                    <Text>Player Score: {playerScore}</Text>
                    <Text>Leaderboard:</Text>
                    {leaderboard.map((player, index) => (
                        <Text key={index}>
                            {player.rank}. {player.address} - {player.score}
                        </Text>
                    ))}
                </View>
            )}
        </View>
    );
};

// ===== FLUTTER EXAMPLE =====

/*
import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

class StrideonScoresFlutter extends StatefulWidget {
  @override
  _StrideonScoresFlutterState createState() => _StrideonScoresFlutterState();
}

class _StrideonScoresFlutterState extends State<StrideonScoresFlutter> {
  late Web3Client client;
  late DeployedContract strideonScoresContract;
  String? userAddress;
  int playerScore = 0;

  @override
  void initState() {
    super.initState();
    initializeWeb3();
  }

  void initializeWeb3() {
    client = Web3Client('http://192.168.31.172:8545', http.Client());
    // Initialize contract with ABI and address
  }

  Future<void> getPlayerScore() async {
    try {
      final result = await client.call(
        contract: strideonScoresContract,
        function: strideonScoresContract.function('getPlayerScore'),
        params: [userAddress!],
      );
      setState(() {
        playerScore = result.first.toInt();
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🏃‍♂️ StrideonScores')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: getPlayerScore,
            child: Text('Get Player Score'),
          ),
          Text('Score: $playerScore'),
        ],
      ),
    );
  }
}
*/

// Export for use in mobile apps
export { StrideonScoresMobile };

// Example usage
if (typeof window !== 'undefined') {
    // Browser environment - for testing
    const mobileApp = new StrideonScoresMobile();
    console.log('📱 Mobile app initialized');
    console.log('🔗 Network:', mobileApp.networkConfig.rpcUrl);
    console.log('📋 Contracts:', mobileApp.contractAddresses);
}
