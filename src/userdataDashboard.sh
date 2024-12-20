#!/bin/bash

# Update the system and install nginx
yum update -y
yum install -y nginx

# Start and enable nginx service
systemctl start nginx
systemctl enable nginx

# Write the inline HTML content to the Nginx web root directory
cat <<'EOL' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Sales Dashboard</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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

    /* Input and Button Styling */
    input[type="text"] {
      width: 300px;
      padding: 10px;
      margin: 10px;
      border: 1px solid #ddd;
      border-radius: 5px;
      font-size: 1rem;
      outline: none;
      transition: border-color 0.3s;
    }

    input[type="text"]:focus {
      border-color: #4CAF50;
    }

    button {
      padding: 10px 20px;
      margin: 10px;
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

    /* Statistics Section */
    #stats {
      margin: 20px auto;
      max-width: 600px;
      background: #fff;
      border-radius: 8px;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
      padding: 20px;
    }

    #stats h2 {
      text-align: center;
      font-size: 1.8rem;
      margin-bottom: 15px;
      color: #333;
    }

    #stats p {
      font-size: 1.2rem;
      margin: 10px 0;
      padding: 5px;
      text-align: center;
      border-bottom: 1px solid #ddd;
    }

    #stats p:last-child {
      border-bottom: none;
    }

    /* Chart Styling */
    canvas {
      display: block;
      margin: 20px auto;
      max-width: 90%;
      background: #fff;
      border-radius: 8px;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
      padding: 10px;
    }

    /* Responsive Design */
    @media screen and (max-width: 768px) {
      input[type="text"] {
        width: 90%;
      }

      button {
        width: 90%;
        margin: 10px auto;
        display: block;
      }

      #stats {
        max-width: 90%;
      }
    }
  </style>
</head>
<body>
  <h1>Sales Dashboard</h1>
  <div style="text-align: center;">
    <input id="businessKey" type="text" placeholder="Enter Business Key" />
    <button onclick="fetchData()">Get Data</button>
  </div>
  <canvas id="revenueChart"></canvas>
  <div id="stats">
    <h2>Statistics</h2>
    <p id="uniqueUsers">Unique Users: </p>
    <p id="totalRevenue">Total Revenue: </p>
    <p id="avgItems">Average Items per Sale: </p>
    <p id="totalSales">Total Sales: </p>
  </div>
  <script>
    function fetchData() {
      const businessKey = document.getElementById("businessKey").value;

      // Fetch data from backend API
      fetch('https://121e8hp3j8.execute-api.eu-north-1.amazonaws.com/CloudProject/FetchSales', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ "KEY": businessKey })
      })
        .then(response => {
          if (!response.ok) {
            throw new Error("Failed to fetch sales data.");
          }
          return response.json();
        })
        .then(salesData => {
            console.log(salesData);
          
            // Parse sales data for the chart
            const labels = salesData.map(sale => {
              const date = new Date(sale.TimeOfSale * 1000); // Convert seconds to milliseconds
              const day = date.getDate(); // Get day
              const month = date.getMonth() + 1; // Get month (months are zero-indexed)
              return `${day} / ${month}`; // Format as 'day/month'
            });
            const saleAmounts = salesData.map(sale => sale.SaleAmount);
          
            // Calculate statistics
            const uniqueUsers = new Set(salesData.map(sale => sale.UserID)).size;
            const totalRevenue = salesData.reduce((sum, sale) => sum + sale.SaleAmount, 0);
            const avgItems = salesData.reduce((sum, sale) => sum + Object.keys(sale.ItemNames).length, 0) / salesData.length;
            const totalSales = salesData.length;
          
            // Update statistics in the DOM
            document.getElementById("uniqueUsers").innerText = `Unique Users: ${uniqueUsers}`;
            document.getElementById("totalRevenue").innerText = `Total Revenue: ${totalRevenue.toFixed(2)}`;
            document.getElementById("avgItems").innerText = `Average Items per Sale: ${avgItems.toFixed(2)}`;
            document.getElementById("totalSales").innerText = `Total Sales: ${totalSales}`;
          
            // Render Chart.js chart
            const ctx = document.getElementById('revenueChart').getContext('2d');
            new Chart(ctx, {
              type: 'line',
              data: {
                labels: labels, // TimeOfSale as 'day/month'
                datasets: [{
                  label: 'Sales Amount ($)',
                  data: saleAmounts, // SaleAmount as data points
                  borderColor: 'rgba(75, 192, 192, 1)',
                  backgroundColor: 'rgba(75, 192, 192, 0.2)',
                  borderWidth: 2,
                  tension: 0.4 // Smooth line
                }]
              },
              options: {
                responsive: true,
                plugins: {
                  legend: { display: true },
                  tooltip: { enabled: true }
                },
                scales: {
                  x: { 
                    title: { display: true, text: 'Date (day/month)' },
                    ticks: {
                      maxRotation: 0,
                      autoSkip: true // Skip overlapping labels
                    }
                  },
                  y: { 
                    title: { display: true, text: 'Sale Amount ($)' }, 
                    beginAtZero: true 
                  }
                }
              }
            });
          })
    }
  </script>
</body>
</html>
EOL

# Restart Nginx to apply changes
systemctl restart nginx