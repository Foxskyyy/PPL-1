package models

import (
	"fmt"
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	Username     string    `json:"username" gorm:"unique"`
	Email        string    `json:"email" gorm:"unique"`
	Password     string    `json:"-"`
	DisplayName  string    `json:"displayname"`
	RefreshToken string    `json:"refresh_token,omitempty"`
	Verified     bool      `json:"verified" gorm:"default:false"`
	VerifyToken  string    `json:"verify_token" gorm:"default:null"`
	CreatedAt    time.Time `json:"created_at"`
}

type UserGroup struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Name      string    `json:"name" gorm:"unique"`
	CreatedAt time.Time `json:"created_at"`
	Devices   []Device  `json:"devices"`
}

type UserGroupMember struct {
	UserID      uint      `json:"user_id"`
	UserGroupID uint      `json:"user_group_id"`
	CreatedAt   time.Time `json:"created_at"`
}

func (ugm *UserGroupMember) BeforeCreate(tx *gorm.DB) error {
	var count int64
	tx.Model(&UserGroupMember{}).Where("user_group_id = ?", ugm.UserGroupID).Count(&count)
	if count >= 4 {
		return fmt.Errorf("a user group cannot have more than 4 users")
	}
	return nil
}

type Device struct {
	ID          string       `json:"id" gorm:"primaryKey"`
	UserGroupID uint         `json:"user_group_id"`
	UserGroup   UserGroup    `json:"-" gorm:"constraint:OnDelete:CASCADE;"`
	Name        string       `json:"name"`
	Location    string       `json:"location"`
	CreatedAt   time.Time    `json:"created_at"`
	WaterUsages []WaterUsage `json:"water_usages"`
}

type WaterUsage struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	DeviceID   string    `json:"device_id"`
	Device     Device    `json:"-" gorm:"constraint:OnDelete:CASCADE;foreignKey:DeviceID;references:ID"`
	FlowRate   float64   `json:"flow_rate"`
	TotalUsage float64   `json:"total_usage"`
	RecordedAt time.Time `json:"recorded_at" gorm:"type:timestamp"`
}

type ElectricityUsage struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	UserID     uint      `json:"user_id"`
	User       User      `json:"-" gorm:"constraint:OnDelete:CASCADE;"`
	TotalUsage float64   `json:"total_usage"`
	RecordedAt time.Time `json:"recorded_at"`
}
