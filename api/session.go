package api

import (
	"encoding/gob"
	"net/http"
	"strings"

	"github.com/alireza0/s-ui/database/model"

	"github.com/gin-contrib/sessions"
	"github.com/gin-gonic/gin"
)

const (
	loginUser = "LOGIN_USER"
)

func init() {
	gob.Register(model.User{})
}

func getSessionOptions(c *gin.Context, maxAge int) sessions.Options {
	return sessions.Options{
		Path:     "/",
		MaxAge:   maxAge,
		HttpOnly: true,
		Secure:   c.Request.TLS != nil || strings.EqualFold(c.GetHeader("X-Forwarded-Proto"), "https"),
		SameSite: http.SameSiteLaxMode,
	}
}

func SetLoginUser(c *gin.Context, userName string, maxAge int) error {
	maxAgeSeconds := 0
	if maxAge > 0 {
		maxAgeSeconds = maxAge * 60
	}
	options := getSessionOptions(c, maxAgeSeconds)

	s := sessions.Default(c)
	s.Set(loginUser, userName)
	s.Options(options)

	return s.Save()
}

func SetMaxAge(c *gin.Context) error {
	s := sessions.Default(c)
	s.Options(getSessionOptions(c, 0))
	return s.Save()
}

func GetLoginUser(c *gin.Context) string {
	s := sessions.Default(c)
	obj := s.Get(loginUser)
	if obj == nil {
		return ""
	}
	objStr, ok := obj.(string)
	if !ok {
		return ""
	}
	return objStr
}

func IsLogin(c *gin.Context) bool {
	return GetLoginUser(c) != ""
}

func ClearSession(c *gin.Context) {
	s := sessions.Default(c)
	s.Clear()
	s.Options(getSessionOptions(c, -1))
	s.Save()
}
