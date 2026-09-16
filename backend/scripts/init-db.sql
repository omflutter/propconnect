-- Database Initialization Script for PropConnect MySQL Database

CREATE DATABASE IF NOT EXISTS `propconnect_db` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `propconnect_db`;

-- Users Table
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(128) NOT NULL,
  `email` VARCHAR(128) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('admin', 'agent', 'buyer', 'seller') NOT NULL DEFAULT 'agent',
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Properties Table
CREATE TABLE IF NOT EXISTS `properties` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `price` DECIMAL(15, 2) NOT NULL,
  `location` VARCHAR(255) NOT NULL,
  `propertyType` VARCHAR(64) NOT NULL DEFAULT 'Apartment',
  `bedrooms` INT UNSIGNED DEFAULT 1,
  `bathrooms` INT UNSIGNED DEFAULT 1,
  `areaSqFt` DOUBLE NULL,
  `status` ENUM('available', 'sold', 'rented', 'pending') NOT NULL DEFAULT 'available',
  `agentId` INT UNSIGNED NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`agentId`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
