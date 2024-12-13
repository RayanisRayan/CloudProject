#!/bin/bash

# Update the system and install nginx
yum update -y
yum install -y nginx

# Start and enable nginx service
systemctl start nginx
systemctl enable nginx

# Add a dummy favicon to prevent 404 error
echo "" > /usr/share/nginx/html/favicon.ico

# Write the HTML content to the Nginx web root directory
cat <<'EOL' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Feedback Form</title>
  <style>
    /* General Styling */
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f9;
      margin: 0;
      padding: 0;
      color: #333;
    }

    h1 {
      text-align: center;
      font-size: 2.5rem;
      color: #4CAF50;
      margin: 20px 0;
    }

    form {
      max-width: 600px;
      margin: 20px auto;
      background: #fff;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    }

    label {
      display: block;
      font-size: 1rem;
      margin-bottom: 5px;
      color: #333;
    }

    input, select, textarea {
      width: calc(100% - 20px);
      padding: 10px;
      margin-bottom: 20px;
      border: 1px solid #ddd;
      border-radius: 5px;
      font-size: 1rem;
      outline: none;
      transition: border-color 0.3s;
    }

    input:focus, select:focus, textarea:focus {
      border-color: #4CAF50;
    }

    button {
      padding: 10px 20px;
      font-size: 1rem;
      color: #fff;
      background-color: #4CAF50;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      transition: background-color 0.3s, transform 0.2s;
    }

    button:hover {
      background-color: #45a049;
      transform: scale(1.05);
    }

    #message {
      text-align: center;
      font-size: 1rem;
      color: green;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <h1>Submit Feedback</h1>
  <form id="feedbackForm">
    <label for="saleID">Sale ID</label>
    <input type="text" id="saleID" name="saleID" required placeholder="Enter Sale ID">

    <label for="shoppingExperience">Shopping Experience</label>
    <select id="shoppingExperience" name="shoppingExperience" required>
      <option value="" disabled selected>Select</option>
      <option value="Excellent">Excellent</option>
      <option value="Good">Good</option>
      <option value="Average">Average</option>
      <option value="Poor">Poor</option>
    </select>

    <label for="qualityOfProducts">Quality of Products</label>
    <select id="qualityOfProducts" name="qualityOfProducts" required>
      <option value="" disabled selected>Select</option>
      <option value="Excellent">Excellent</option>
      <option value="Good">Good</option>
      <option value="Average">Average</option>
      <option value="Poor">Poor</option>
    </select>

    <label for="wouldPurchaseAgain">Would Purchase Again?</label>
    <select id="wouldPurchaseAgain" name="wouldPurchaseAgain" required>
      <option value="" disabled selected>Select</option>
      <option value="Yes">Yes</option>
      <option value="No">No</option>
    </select>

    <label for="comments">Comments</label>
    <textarea id="comments" name="comments" rows="4" required placeholder="Enter your comments here"></textarea>

    <button type="button" onclick="submitFeedback()">Submit Feedback</button>
  </form>
  <div class="message" id="message"></div>

  <script>
    function submitFeedback() {
      // Get form values
      const saleID = document.getElementById("saleID").value;
      const shoppingExperience = document.getElementById("shoppingExperience").value;
      const qualityOfProducts = document.getElementById("qualityOfProducts").value;
      const wouldPurchaseAgain = document.getElementById("wouldPurchaseAgain").value;
      const comments = document.getElementById("comments").value;

      // Fetch the API endpoint using POST
      fetch("https://1pmbdyw7r2.execute-api.eu-north-1.amazonaws.com/CloudProject/Feedback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          SaleID: saleID,
          ShoppingExperience: shoppingExperience,
          QualityOfProducts: qualityOfProducts,
          WouldPurchaseAgain: wouldPurchaseAgain,
          Comments: comments
        })
      })
      .then(response => {
        if (!response.ok) {
          throw new Error("Failed to submit feedback.");
        }
        return response.json();
      })
      .then(data => {
        document.getElementById("message").innerText = "Feedback submitted successfully!";
        console.log("Feedback submitted successfully", data);
      })
      .catch(error => {
        document.getElementById("message").innerText = "Error submitting feedback.";
        console.error("Error submitting feedback:", error);
      });
    }
  </script>
</body>
</html>
EOL

# Restart Nginx to apply changes
systemctl restart nginx
