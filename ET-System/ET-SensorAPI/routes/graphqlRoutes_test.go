package routes

import (
	"testing"

	"github.com/gin-gonic/gin"
)

func Test_graphqlHandler(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		want gin.HandlerFunc
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := graphqlHandler()
			// TODO: update the condition below to compare got with tt.want.
			if true {
				t.Errorf("graphqlHandler() = %v, want %v", got, tt.want)
			}
		})
	}
}
