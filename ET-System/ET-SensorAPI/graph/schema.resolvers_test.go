package graph

import (
	"ET-SensorAPI/graph/model"
	"context"
	"testing"
)

func Test_queryResolver_WaterUsageComparisonByGroup(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		groupID int32
		want    *model.WaterUsageComparison
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// TODO: construct the receiver type.
			var r queryResolver
			got, gotErr := r.WaterUsageComparisonByGroup(context.Background(), tt.groupID)
			if gotErr != nil {
				if !tt.wantErr {
					t.Errorf("WaterUsageComparisonByGroup() failed: %v", gotErr)
				}
				return
			}
			if tt.wantErr {
				t.Fatal("WaterUsageComparisonByGroup() succeeded unexpectedly")
			}
			// TODO: update the condition below to compare got with tt.want.
			if true {
				t.Errorf("WaterUsageComparisonByGroup() = %v, want %v", got, tt.want)
			}
		})
	}
}
