package routes

import (
	"ET-SensorAPI/graphql"
	"net/http"

	"github.com/gin-gonic/gin"
	gql "github.com/graphql-go/graphql"
)

func GraphQLHandler(c *gin.Context) {
	var query struct {
		Query string `json:"query"`
	}
	if err := c.ShouldBindJSON(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := gql.Do(gql.Params{
		Schema:        graphql.Schema,
		RequestString: query.Query,
	})
	c.JSON(http.StatusOK, result)
}

func SetupGraphQLRoutes(r *gin.Engine) {
	r.GET("/graphql", GraphQLHandler)
}
