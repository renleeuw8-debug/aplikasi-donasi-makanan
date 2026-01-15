/**
 * Admin Panel Main JS
 */

document.addEventListener("DOMContentLoaded", function () {
  // Initialize tooltips
  const tooltipTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="tooltip"]')
  );
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Auto hide alerts
  const alerts = document.querySelectorAll(".alert");
  alerts.forEach(function (alert) {
    setTimeout(function () {
      const bsAlert = new bootstrap.Alert(alert);
      bsAlert.close();
    }, 5000);
  });
});

/**
 * API Helper Function
 */
function apiCall(method, endpoint, data = null) {
  const options = {
    method: method,
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + getToken(),
    },
  };

  if (data) {
    options.body = JSON.stringify(data);
  }

  return fetch("http://localhost:3000/api" + endpoint, options)
    .then((response) => response.json())
    .then((data) => {
      if (data.success) {
        showAlert("success", data.message || "Operasi berhasil");
        return data;
      } else {
        showAlert("danger", data.message || "Terjadi kesalahan");
        return null;
      }
    })
    .catch((error) => {
      console.error("API Error:", error);
      showAlert("danger", "Gagal terhubung ke server");
      return null;
    });
}

/**
 * Get API Token from Session Storage
 */
function getToken() {
  return sessionStorage.getItem("api_token") || "";
}

/**
 * Show Alert
 */
function showAlert(type, message) {
  const alertHTML = `
        <div class="alert alert-${type} alert-dismissible fade show" role="alert">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;

  const container = document.querySelector(".main-content");
  const alertDiv = document.createElement("div");
  alertDiv.innerHTML = alertHTML;

  if (container) {
    container.insertBefore(alertDiv.firstChild, container.firstChild);
  }
}

/**
 * Format Currency
 */
function formatCurrency(amount) {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
  }).format(amount);
}

/**
 * Format Date
 */
function formatDate(date) {
  return new Intl.DateTimeFormat("id-ID", {
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(new Date(date));
}
