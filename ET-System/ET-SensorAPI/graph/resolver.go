package graph

import "gorm.io/gorm"

// Resolver serves as dependency injection for your app, add any dependencies you require here.
type Resolver struct {
	DB *gorm.DB
}
