package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	Email        string    `json:"email" gorm:"unique"`
	Password     string    `json:"-"`
	DisplayName  string    `json:"displayname"`
	RefreshToken string    `json:"refresh_token,omitempty"`
	Verified     bool      `json:"verified" gorm:"default:false"`
	VerifyToken  string    `json:"verify_token" gorm:"default:null"`
	Provider     string    `json:"provider"`
	ProviderID   string    `json:"provider_id"`
	CreatedAt    time.Time `json:"created_at"`
}

type UserGroup struct {
	ID        uint   `gorm:"primaryKey"`
	Name      string `gorm:"unique"`
	CreatedAt time.Time
	Devices   []Device  `gorm:"foreignKey:UserGroupID"`
	Location  JSONArray `gorm:"type:jsonb"`
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
	ID          string    `gorm:"primaryKey"`
	UserGroupID uint      `gorm:"index"`
	UserGroup   UserGroup `gorm:"constraint:OnDelete:CASCADE;"`
	Name        string
	Location    string
	CreatedAt   time.Time
	WaterUsages []WaterUsage `gorm:"foreignKey:DeviceID"`
}

type WaterUsage struct {
	ID         uint   `gorm:"primaryKey"`
	DeviceID   string `gorm:"index"`
	Device     Device `gorm:"constraint:OnDelete:CASCADE;"`
	FlowRate   float64
	TotalUsage float64
	RecordedAt time.Time `gorm:"index"`
}

type Notification struct {
	ID        uint   `gorm:"primaryKey"`
	DeviceID  string `gorm:"index"`
	Device    Device `gorm:"foreignKey:DeviceID;references:ID"`
	Message   string
	Threshold float64
	CreatedAt time.Time
}

type DailyUsage struct {
	ID         uint      `gorm:"primaryKey"`
	DeviceID   string    `gorm:"index"`
	Date       time.Time `gorm:"type:date"`
	TotalUsage float64
	Notified   bool `gorm:"default:false"`
}

type JSONArray []string

func (j *JSONArray) Scan(value interface{}) error {
	if value == nil {
		*j = JSONArray{}
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("invalid type assertion")
	}
	return json.Unmarshal(bytes, j)
}

func (j JSONArray) Value() (driver.Value, error) {
	if j == nil {
		return "[]", nil
	}
	return json.Marshal(j)
}
