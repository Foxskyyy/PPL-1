package utils_test

import (
	"ET-SensorAPI/utils"
	"testing"
)

func TestAnalyzeUsageData(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		input   string
		want    string
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, gotErr := utils.AnalyzeUsageData(tt.input)
			if gotErr != nil {
				if !tt.wantErr {
					t.Errorf("AnalyzeUsageData() failed: %v", gotErr)
				}
				return
			}
			if tt.wantErr {
				t.Fatal("AnalyzeUsageData() succeeded unexpectedly")
			}
			// TODO: update the condition below to compare got with tt.want.
			if true {
				t.Errorf("AnalyzeUsageData() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestAnalyzeUsageData(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		input   string
		want    string
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, gotErr := utils.AnalyzeUsageData(tt.input)
			if gotErr != nil {
				if !tt.wantErr {
					t.Errorf("AnalyzeUsageData() failed: %v", gotErr)
				}
				return
			}
			if tt.wantErr {
				t.Fatal("AnalyzeUsageData() succeeded unexpectedly")
			}
			// TODO: update the condition below to compare got with tt.want.
			if true {
				t.Errorf("AnalyzeUsageData() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestAnalyzeUsageData(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		input   string
		want    string
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, gotErr := utils.AnalyzeUsageData(tt.input)
			if gotErr != nil {
				if !tt.wantErr {
					t.Errorf("AnalyzeUsageData() failed: %v", gotErr)
				}
				return
			}
			if tt.wantErr {
				t.Fatal("AnalyzeUsageData() succeeded unexpectedly")
			}
			// TODO: update the condition below to compare got with tt.want.
			if true {
				t.Errorf("AnalyzeUsageData() = %v, want %v", got, tt.want)
			}
		})
	}
}
