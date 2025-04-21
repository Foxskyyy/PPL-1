package graph

import (
	"ET-SensorAPI/graph/model"
	"context"
	"time"
)

// WaterUsageComparisonByGroup is the resolver for the waterUsageComparisonByGroup field.
func (r *queryResolver) WaterUsageComparisonByGroup(ctx context.Context, groupID int32) (*model.WaterUsageComparison, error) {
	now := time.Now().UTC()
	currentMonthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	previousMonthStart := currentMonthStart.AddDate(0, -1, 0)
	previousMonthEnd := currentMonthStart.Add(-time.Second)

	var currentMonthUsages []*model.WaterUsage
	if err := r.DB.
		Joins("JOIN devices ON devices.id = water_usages.device_id").
		Where("devices.user_group_id = ?", groupID).
		Where("water_usages.recorded_at BETWEEN ? AND ?", currentMonthStart, now).
		Find(&currentMonthUsages).Error; err != nil {
		return nil, err
	}

	currentMonthTotal := 0.0
	for _, usage := range currentMonthUsages {
		currentMonthTotal += usage.TotalUsage
	}

	var previousMonthUsages []*model.WaterUsage
	if err := r.DB.
		Joins("JOIN devices ON devices.id = water_usages.device_id").
		Where("devices.user_group_id = ?", groupID).
		Where("water_usages.recorded_at BETWEEN ? AND ?", previousMonthStart, previousMonthEnd).
		Find(&previousMonthUsages).Error; err != nil {
		return nil, err
	}

	previousMonthTotal := 0.0
	for _, usage := range previousMonthUsages {
		previousMonthTotal += usage.TotalUsage
	}

	return &model.WaterUsageComparison{
		CurrentMonth: &model.MonthlyWaterUsage{
			TotalUsage: currentMonthTotal,
			Usages:     currentMonthUsages,
		},
		PreviousMonth: &model.MonthlyWaterUsage{
			TotalUsage: previousMonthTotal,
			Usages:     previousMonthUsages,
		},
	}, nil
}

// WaterUsageComparisonByUser is the resolver for the waterUsageComparisonByUser field.
func (r *queryResolver) WaterUsageComparisonByUser(ctx context.Context, userID int32) (*model.WaterUsageComparison, error) {
	now := time.Now().UTC()
	currentMonthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
	previousMonthStart := currentMonthStart.AddDate(0, -1, 0)
	previousMonthEnd := currentMonthStart.Add(-time.Second)

	var groupIDs []int
	if err := r.DB.
		Table("user_groups_users").
		Where("user_id = ?", userID).
		Pluck("user_group_id", &groupIDs).Error; err != nil {
		return nil, err
	}

	if len(groupIDs) == 0 {
		return &model.WaterUsageComparison{
			CurrentMonth: &model.MonthlyWaterUsage{
				TotalUsage: 0,
				Usages:     []*model.WaterUsage{},
			},
			PreviousMonth: &model.MonthlyWaterUsage{
				TotalUsage: 0,
				Usages:     []*model.WaterUsage{},
			},
		}, nil
	}

	var currentMonthUsages []*model.WaterUsage
	if err := r.DB.
		Preload("Device").
		Joins("JOIN devices ON devices.id = water_usages.device_id").
		Where("devices.user_group_id IN ?", groupIDs).
		Where("water_usages.recorded_at BETWEEN ? AND ?", currentMonthStart, now).
		Find(&currentMonthUsages).Error; err != nil {
		return nil, err
	}

	currentMonthTotal := 0.0
	for _, usage := range currentMonthUsages {
		currentMonthTotal += usage.TotalUsage
	}

	var previousMonthUsages []*model.WaterUsage
	if err := r.DB.
		Preload("Device").
		Joins("JOIN devices ON devices.id = water_usages.device_id").
		Where("devices.user_group_id IN ?", groupIDs).
		Where("water_usages.recorded_at BETWEEN ? AND ?", previousMonthStart, previousMonthEnd).
		Find(&previousMonthUsages).Error; err != nil {
		return nil, err
	}

	previousMonthTotal := 0.0
	for _, usage := range previousMonthUsages {
		previousMonthTotal += usage.TotalUsage
	}

	return &model.WaterUsageComparison{
		CurrentMonth: &model.MonthlyWaterUsage{
			TotalUsage: currentMonthTotal,
			Usages:     currentMonthUsages,
		},
		PreviousMonth: &model.MonthlyWaterUsage{
			TotalUsage: previousMonthTotal,
			Usages:     previousMonthUsages,
		},
	}, nil
}
