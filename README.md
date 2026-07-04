# NodeOps — Node Inventory Management App

A production-ready Flutter mobile application for managing multi-node warehouse and inventory operations. Built for node admins who need a fast, intuitive interface for shipments, GRN, audit, returns, and adjustments.

---

## ✨ Features

### ✅ Phase 1 (Complete)
| Feature | Status |
|---|---|
| Login with Node Selection | ✅ Full UI + dummy auth |
| Home Dashboard | ✅ Stats, quick actions, activity feed |
| Shipment List (tabbed) | ✅ All status tabs + search |
| Create Shipment from Order | ✅ Order picker + line item selector with node stock |
| Shipment Detail + Timeline | ✅ Animated progress timeline |
| Allocation (batch/serial/untracked) | ✅ Full manual + auto-allocate |
| Dispatch with Driver Details | ✅ Form + validation |
| Mark as Delivered | ✅ One-click with confirm dialog |

### 🏗️ Phase 2 (Scaffolded, Coming Soon)
- GRN (PO-based, batch/serial/untracked inwarding)
- Inventory Audit
- Returns / Replacements
- Inventory Adjustment

---

## 🛠 Tech Stack

| Concern | Package | Why |
|---|---|---|
| **State Management** | `flutter_riverpod ^2.6.1` | Compile-safe, testable, scalable |
| **Routing** | `go_router ^15.1.2` | Declarative routes, deep-linking, shell routes |
| **Network** | `dio ^5.8.0` | Interceptors, timeout, auth token injection |
| **Secure Storage** | `flutter_secure_storage ^9.2.4` | JWT + session persistence |
| **Typography** | `google_fonts ^6.2.1` | Inter font family |

---

## 📁 Folder Structure (Feature-First)

```
lib/
├── main.dart                          # Entry: ProviderScope + portrait lock
├── app/
│   ├── app.dart                       # MaterialApp.router + theme
│   ├── router/
│   │   └── app_router.dart            # GoRouter: auth guard, StatefulShellRoute, all routes
│   └── theme/
│       ├── app_colors.dart            # Color palette (dark navy + indigo/cyan accents)
│       ├── app_text_styles.dart       # Typography (Inter via Google Fonts)
│       └── app_theme.dart             # Full ThemeData for all components
├── core/
│   ├── constants/app_constants.dart   # App-wide constants, status strings
│   ├── network/
│   │   ├── dio_client.dart            # Dio singleton + auth interceptor
│   │   └── api_endpoints.dart         # All API URL strings
│   ├── storage/secure_storage.dart    # Typed wrapper for FlutterSecureStorage
│   ├── providers/core_providers.dart  # dioProvider, secureStorageProvider
│   └── widgets/
│       ├── app_button.dart            # Gradient button with press animation
│       ├── app_text_field.dart        # Text field with password toggle
│       ├── status_badge.dart          # Colored pill badge per shipment status
│       ├── loading_overlay.dart       # Loading spinner overlay
│       └── placeholder_screen.dart   # "Coming soon" screen for unbuilt features
└── features/
    ├── auth/
    │   ├── data/models/               # LoginRequest, UserModel, NodeModel
    │   ├── data/repositories/         # AuthRepository (dummy → real API swap)
    │   ├── providers/auth_provider.dart  # AuthNotifier (StateNotifier)
    │   └── presentation/screens/      # LoginScreen
    ├── home/
    │   ├── data/models/               # DashboardStats, ActivityItem
    │   ├── providers/                 # (home_provider placeholder)
    │   └── presentation/
    │       ├── screens/home_screen.dart
    │       └── widgets/               # StatCard, QuickActionTile, RecentActivityCard
    ├── shipment/
    │   ├── data/models/               # Order, Product, Shipment, ShipmentLineItem, etc.
    │   ├── data/repositories/         # ShipmentRepository (in-memory dummy)
    │   ├── providers/shipment_provider.dart  # ShipmentListNotifier
    │   └── presentation/
    │       ├── screens/
    │       │   ├── shipment_list_screen.dart   # Tabbed list + search
    │       │   ├── create_shipment_screen.dart # 2-step order → items
    │       │   ├── shipment_detail_screen.dart # Timeline + actions
    │       │   ├── allocation_screen.dart      # batch/serial/untracked
    │       │   └── dispatch_screen.dart        # Driver details form
    │       └── widgets/                         # ShipmentCard
    ├── grn/        → PlaceholderScreen (Phase 2)
    ├── audit/      → PlaceholderScreen (Phase 2)
    ├── returns/    → PlaceholderScreen (Phase 2)
    └── adjustment/ → PlaceholderScreen (Phase 2)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.10.3
- Dart SDK ≥ 3.10.3
- Android Studio / VS Code with Flutter extension

### Run the app
```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

### Demo Login
| Field | Value |
|---|---|
| **Node** | Any (Warehouse Alpha, Beta, etc.) |
| **Username** | `admin` |
| **Password** | `password123` |

---

## 🔄 Shipment Flow

```
Order (confirmed)
    ↓ Create Shipment (select items + qty)
Created
    ↓ Allocate (batch / serial / untracked per product)
Allocated
    ↓ Invoice (one tap)
Invoiced
    ↓ Dispatch (enter driver name, phone, vehicle)
Dispatched
    ↓ Deliver (one tap + confirm)
Delivered
    ↓ Initiate Return (Phase 2 — good/bad qty, reason)
Return Initiated
    ↓ Complete Return
Return Completed
```

---

## 🎨 Design System

| Token | Value |
|---|---|
| Background | `#080B18` |
| Surface | `#0F1427` |
| Card | `#161D35` |
| Primary | `#5B8AF6` (indigo blue) |
| Secondary | `#00D4FF` (cyan) |
| Accent | `#A855F7` (purple) |
| Success | `#22C55E` |
| Warning | `#F59E0B` |
| Error | `#EF4444` |
| Font | Inter (Google Fonts) |

---

## 🔌 API Integration

All API endpoints are in `lib/core/network/api_endpoints.dart`.  
Replace `ApiEndpoints.baseUrl` with your actual server URL.

The `AuthRepository` and `ShipmentRepository` contain commented-out real API calls alongside the dummy implementations. Switch by:
1. Setting `baseUrl` in `api_endpoints.dart`
2. Uncommenting the real API code in each repository
3. Removing the `await Future.delayed(...)` simulate calls

The Dio client automatically injects the `Authorization: Bearer <token>` header on every request after login.

---

## 📱 Tracking Types

| Type | Allocation Method |
|---|---|
| **Batch** | Enter batch codes with qty per batch (multiple batches supported) |
| **Serial** | Select individual serial numbers from node inventory |
| **Untracked** | No allocation needed, auto-marked |

---

## 🗂 State Management Pattern

```
UI → ref.read(provider.notifier).action()
           ↓
     StateNotifier updates state
           ↓
UI auto-rebuilds via ref.watch(provider)
```

Auth state is bridged to GoRouter via `_RouterNotifier extends ChangeNotifier`, which calls `notifyListeners()` whenever auth state changes, triggering GoRouter's redirect logic.

---

## 📋 Roles & Access (Planned)

The auth response will include role information. The following features are role-gated:
- **Direct GRN**: Only visible if the user's role includes `direct_grn` permission
- **Inventory Adjustment**: Requires `adjustment` role
- **Audit**: Requires `audit` role

---

## 🧪 Testing

```bash
flutter test
flutter analyze
```
