# ♻️ Recycling Reward System Smart Contract

A blockchain-based incentive system that rewards users for recycling activities using Clarity smart contracts on Stacks.

## 🌟 Features

- 👤 **User Registration**: Register with a unique name and track your recycling journey
- 📊 **Material Types**: Support for different recyclable materials with varying point values
- 📝 **Submission Tracking**: Submit recycling activities for verification
- ✅ **Admin Verification**: Contract owner verifies submissions and awards points
- 🏆 **Reward System**: Redeem points for rewards and track your achievements
- 📈 **Statistics**: View user stats including total points and recycling count

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js for testing

### Installation
```bash
git clone <repository-url>
cd Recycling-Reward-System
clarinet check
npm install
npm test
```

## 📋 Contract Functions

### User Functions

#### `register-user`
Register a new user in the system
```clarity
(register-user "Your Name")
```

#### `submit-recycling`
Submit a recycling activity for verification
```clarity
(submit-recycling material-id quantity)
```

#### `redeem-reward`
Redeem points for available rewards
```clarity
(redeem-reward reward-id quantity)
```

### Admin Functions

#### `add-material-type`
Add a new recyclable material type with point value
```clarity
(add-material-type "Plastic Bottles" u10)
```

#### `verify-submission`
Verify and approve a recycling submission
```clarity
(verify-submission submission-id)
```

#### `add-reward`
Create new rewards for users to redeem
```clarity
(add-reward "Coffee Cup" "Free coffee at partner stores" u100)
```

### Read-Only Functions

#### `get-user-by-address`
Get user information by wallet address
```clarity
(get-user-by-address 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### `calculate-points`
Calculate points for a material and quantity
```clarity
(calculate-points material-id quantity)
```

#### `get-user-stats`
Get comprehensive user statistics
```clarity
(get-user-stats user-id)
```

## 🎯 Usage Examples

### 1. Register as a User
```clarity
(contract-call? .recycling-reward-system register-user "Alice Green")
```

### 2. Admin Adds Material Types
```clarity
(contract-call? .recycling-reward-system add-material-type "Aluminum Cans" u15)
(contract-call? .recycling-reward-system add-material-type "Glass Bottles" u8)
(contract-call? .recycling-reward-system add-material-type "Paper" u5)
```

### 3. Submit Recycling Activity
```clarity
(contract-call? .recycling-reward-system submit-recycling u1 u20)
```

### 4. Admin Verifies Submission
```clarity
(contract-call? .recycling-reward-system verify-submission u1)
```

### 5. Add and Redeem Rewards
```clarity
(contract-call? .recycling-reward-system add-reward "Eco Tote Bag" "Reusable shopping bag" u50)
(contract-call? .recycling-reward-system redeem-reward u1 u1)
```

## 📊 Data Structure

### Users
- Unique ID and wallet address
- Name and join date
- Total points earned
- Recycling activity count

### Material Types
- Material name and point value per unit
- Active/inactive status
- Admin-controlled pricing

### Submissions
- User and material information
- Quantity and calculated points
- Verification status and timestamp

### Rewards
- Name, description, and point cost
- Availability status
- User redemption tracking

## 🔒 Security Features

- Owner-only admin functions
- Input validation for all parameters
- Duplicate registration prevention
- Insufficient points checking
- Material and reward availability verification

## 🧪 Testing

Run the test suite:
```bash
npm test
```

Tests cover:
- User registration and management
- Material type operations
- Recycling submission flow
- Reward system functionality
- Error handling scenarios

## 📜 Contract Constants

| Constant | Value | Description |
|----------|--------|-------------|
| `err-owner-only` | 100 | Only contract owner can perform this action |
| `err-not-found` | 101 | Requested resource not found |
| `err-insufficient-points` | 102 | User doesn't have enough points |
| `err-invalid-amount` | 103 | Invalid quantity or amount provided |
| `err-already-exists` | 104 | Resource already exists |
| `err-unauthorized` | 105 | User not authorized for this action |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run `clarinet check` to verify contract validity
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌍 Environmental Impact

By using blockchain technology to incentivize recycling, this system promotes:
- ♻️ Increased recycling participation
- 🌱 Environmental awareness
- 📈 Measurable sustainability metrics
- 🏪 Partnership opportunities with eco-friendly businesses

---

Built with ❤️ for a greener future using Stacks and Clarity
