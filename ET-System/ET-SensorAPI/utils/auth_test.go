package utils_test

import (
	"ET-SensorAPI/utils"
	"testing"
)

func TestSendVerificationEmail(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		email   string
		token   string
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotErr := utils.SendVerificationEmail(tt.email, tt.token)
			if gotErr != nil {
				if !tt.wantErr {
					t.Errorf("SendVerificationEmail() failed: %v", gotErr)
				}
				return
			}
			if tt.wantErr {
				t.Fatal("SendVerificationEmail() succeeded unexpectedly")
			}
		})
	}
}

func TestSendVerificationEmail(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		email   string
		token   string
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotErr := utils.SendVerificationEmail(tt.email, tt.token)
			if gotErr != nil {
				if !tt.wantErr {
					t.Errorf("SendVerificationEmail() failed: %v", gotErr)
				}
				return
			}
			if tt.wantErr {
				t.Fatal("SendVerificationEmail() succeeded unexpectedly")
			}
		})
	}
}
