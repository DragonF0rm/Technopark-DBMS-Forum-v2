package thread

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"io/ioutil"
	"net/http"
)

func VoteHandler(w http.ResponseWriter, r *http.Request) {
	bodyContent, err := ioutil.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	args := struct {
		Nickname   string `json:"nickname"`
		Voice      int    `json:"voice"`
	}{}

	err = json.Unmarshal(bodyContent, &args)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)//Возможно, лучше BadRequest
		return
	}

	code, response := vote(mux.Vars(r)["slug_or_id"], args.Nickname, args.Voice)
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
