const mongoose = require("mongoose");
const axios = require("axios");

const userSchema = mongoose.Schema({
  handle: {
    required: true,
    type: String,
    trim: true,
    validate:{
        validator: (value) => {
            axios.get(`https://codeforces.com/api/user.info?handles=${value}`)
            .then((response) => {
                if(response.data.status === "FAILED") {
                    return false;
                }
                return true;
            })
        },
    }
  },
  email: {
    required: true,
    type: String,
    trim: true,
    validate: {
      validator: (value) => {
        const re =
          /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
        return value.match(re);
      },
      message: "Please enter a valid email address",
    },
  },
  password: {
    required: true,
    type: String,
  },
});

const User = mongoose.model("User", userSchema);
module.exports = User;