const express = require('express');
const reviews = express.Router();
const db = require('../db/');


reviews.get('/', db.getReviewsByProductId);

reviews.put('/:review_id/report', db.reportReview);

reviews.put('/:review_id/helpful', db.markAsHelpful);

reviews.post('/', (req, res) => {
  db.postNewReview;
  console.log(req.body)
  res.status(201).send()
}); //handle new review post
// update client side to use req.body instead of req.params

reviews.get('/benchmark', db.benchmark);

// reviews.get('/meta', db.getAverageRatingByProductId);


module.exports = reviews;
