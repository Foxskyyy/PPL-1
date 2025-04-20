package main

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"ET-SensorAPI/routes"
	"fmt"
	"log"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
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
	)
	if err != nil {
		fmt.Println("❌ Migration failed:", err)
	} else {
		fmt.Println("✅ Migration completed successfully!")
	}

	dir, _ := os.Getwd()
	fmt.Println("Running from:", dir)

	r := gin.Default()
	r.Use(cors.New(cors.Config{
		AllowOrigins:  []string{"*"},
		AllowMethods:  []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:  []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders: []string{"Content-Length"},
		// AllowCredentials: true,
		// MaxAge:           12 * time.Hour,
	}))

	r.Static("/static", "./static")
	routes.SetupRouter(r)
	routes.SetupGraphQLRoutes(r)
	routes.SetupDeepSeekRoutes(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Server running on http://localhost:%s/\n", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
