# 🔐 kilian_locker

A simple and persistent personal locker system for FiveM ESX servers. Players can store and retrieve weapons and items securely from a database-backed locker.

---

## Features

- Store and retrieve weapons and items
- Persistent storage using MySQL (`kilian_locker_db` table)
- Inventory validation (no exploits)
- Weapons and ammo tracked separately
- Syncs with player login via identifier
- Easy integration with any UI/menu system

---

## Requirements

- [ESX Legacy](https://github.com/esx-framework/esx-legacy)
- MySQL/MariaDB
- Inventory system that supports `removeInventoryItem` and `addInventoryItem`

```sql
CREATE TABLE IF NOT EXISTS kilian_locker_db (
    identifier VARCHAR(60) PRIMARY KEY,
    items LONGTEXT,
    weapons LONGTEXT
);

## Author
**Kilian**