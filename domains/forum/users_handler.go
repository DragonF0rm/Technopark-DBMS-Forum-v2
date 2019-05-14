package forum

import (
	"bytes"
	"encoding/json"
	"github.com/gorilla/mux"
	"net/http"
	"strconv"
)

func UsersHandler(w http.ResponseWriter, r *http.Request) {
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil {
		limit = 100
	}
	since := r.URL.Query().Get("since")
	desc, err := strconv.ParseBool(r.URL.Query().Get("desc"))
	if err != nil {
		desc = false
	}

	code, response := users(mux.Vars(r)["slug"], int32(limit), since, desc)
	responseJSON, err := json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	if bytes.Equal(responseJSON,[]byte("null")) {
		responseJSON = []byte("[]")
	}

	w.WriteHeader(code)
	_, err = w.Write(responseJSON)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	return
}
