# Ecommerce App
## Project Title: NED Eats

A mobile food ordering application designed for NED University students, faculty, and canteen supervisors. It allows users to browse canteens, view real time menus, place online orders, and make secure payments, reducing long queues and improving the overall canteen experience.

**Course:** E-Commerce SE-311  
**Department:** Software Engineering  
**Batch:** 2023  
**Project Supervisor:** Dr. Kashif Mehboob Khan  
**Group Members:**  
- SE-23003 Ayesha Mansoor  
- SE-23006 Sabrina Manahil Waseem  
- SE-23018 Sania Siddiqui  
- SE-23027 Abeeha Nadeem  


---

## Installation

### 1. System Requirements
- **Visual Studio Code** or **Android Studio**
- **Flutter SDK**
- **Dart SDK** (comes with Flutter)
- **Environment Variables (PATH)** configured for Flutter and Dart
- **Android Emulator** or a **physical Android device** (USB Debugging enabled)

### 2. Clone the Repository
```bash
git clone https://github.com/Sabrina-manahil-waseem-006/ecommerce_app.git
````

### 3. Open the Project

```bash
cd ecommerce_app
```

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Check Flutter Setup

```bash
flutter doctor
```

### 6. Run on Chrome (Web)

```bash
flutter run -d chrome
```

### 7. Run on Android Emulator

* Open **Android Studio**
* Start an **Android Emulator**

```bash
flutter run
```

### 8. Run on Physical Android Device

* Enable **USB Debugging**
* Connect via USB

```bash
flutter devices
flutter run
```

---

## Usage

The application provides separate interfaces for Users, Supervisors, and Admins:

### Customer/User

* Create account or login
* Browse available canteens
* View real-time menu items and prices
* Add items to cart
* Place orders and receive online confirmation
* Track order status and pickup time
* Make secure online payments via PayFast

### Supervisor

* Login with supervisor credentials
* Manage canteen inventory and update menu items
* View incoming customer orders
* Confirm and process orders
* Manage payments and track transactions

### Admin

* Login with admin credentials
* Approve or reject supervisor registrations
* Authenticate and manage customer accounts
* Monitor all canteens, orders, and payments
* Generate reports for operational oversight

---

## Features

* Real-time menu updates for all canteens
* Online ordering and payment integration with PayFast
* Cloudinary image storage for food items
* Separate dashboards for User, Supervisor, and Admin
* Order tracking system with pickup time notifications
* Cart management for multiple items per order
* Secure login and authentication for all users
* Supports multiple simultaneous users
* Improves operational efficiency and reduces wait times
* User-friendly mobile interface built with Flutter

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Submit a pull request

Contributions are welcome!

---

