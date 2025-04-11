package main

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"ET-SensorAPI/routes"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/handlers"
	"github.com/joho/godotenv"
)

func main() {

	if err := godotenv.Load(); err != nil {
		log.Fatal("Error loading .env file")
	}

	config.ConnectDB()

	err := config.DB.AutoMigrate(
		&models.User{},
		&models.UserGroup{},
		&models.UserGroupMember{},
		&models.Device{},
		&models.WaterUsage{},
		&models.ElectricityUsage{},
	)
	if err != nil {
		fmt.Println("❌ Migration failed:", err)
	} else {
		fmt.Println("✅ Migration completed successfully!")
	}

	dir, _ := os.Getwd()
	fmt.Println("Running from:", dir)

	r := gin.Default()
	r.Static("/static", "./static")
	routes.SetupRouter(r)
	routes.SetupGraphQLRoutes(r)
	routes.SetupDeepSeekRoutes(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Server running on http://localhost:%s/\n", port)
	r.Run(":" + port)
	http.ListenAndServe(":"+port,
		handlers.CORS(
			handlers.AllowedOrigins([]string{"*"}),
			handlers.AllowedMethods([]string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}),
			handlers.AllowedHeaders([]string{"Origin", "Content-Type", "Authorization"}),
		)(r))
}
