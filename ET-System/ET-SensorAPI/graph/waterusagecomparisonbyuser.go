package graph

import (
	"ET-SensorAPI/graph/model"
	"context"
	"fmt"
)

// WaterUsageComparisonByUser is the resolver for the waterUsageComparisonByUser field.
func (r *queryResolver) WaterUsageComparisonByUser(ctx context.Context, userID int32) (*model.WaterUsageComparison, error) {
	panic(fmt.Errorf("not implemented: WaterUsageComparisonByUser - waterUsageComparisonByUser"))
}
