package user

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"io/ioutil"
	"net/http"
)

func CreateHandler(w http.ResponseWriter, r *http.Request) {
	bodyContent, err := ioutil.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	args := struct {
		Fullname string `json:"fullname"`
		About    string `json:"about"`
		Email    string `json:"email"`
	}{}

	err = json.Unmarshal(bodyContent, &args)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)//Возможно, лучше BadRequest
		return
	}

	code, response := create(mux.Vars(r)["nickname"], args.Fullname, args.About, args.Email)
	responseJSON, err := json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(code)
	_, err = w.Write(responseJSON)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	return
}
