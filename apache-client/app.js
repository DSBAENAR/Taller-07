// Configuration - Update this URL with your Spring backend server address
const API_BASE_URL = "https://localhost:8443";

// ---- Tab Switching ----
function switchTab(tab) {
    const tabs = document.querySelectorAll(".tab");
    const loginForm = document.getElementById("loginForm");
    const registerForm = document.getElementById("registerForm");
    const message = document.getElementById("authMessage");

    tabs.forEach((t) => t.classList.remove("active"));
    message.className = "message";
    message.style.display = "none";

    if (tab === "login") {
        tabs[0].classList.add("active");
        loginForm.style.display = "block";
        registerForm.style.display = "none";
    } else {
        tabs[1].classList.add("active");
        loginForm.style.display = "none";
        registerForm.style.display = "block";
    }
}

// ---- Async API Helper ----
async function apiRequest(endpoint, method, body) {
    const options = {
        method: method,
        headers: { "Content-Type": "application/json" },
    };
    if (body) {
        options.body = JSON.stringify(body);
    }

    const response = await fetch(`${API_BASE_URL}${endpoint}`, options);
    const data = await response.json();

    if (!response.ok) {
        throw new Error(data.error || "Request failed");
    }
    return data;
}

// ---- Show Message ----
function showMessage(elementId, text, isError) {
    const el = document.getElementById(elementId);
    el.textContent = text;
    el.className = "message " + (isError ? "error" : "success");
    el.style.display = "block";
}

// ---- Login Handler ----
async function handleLogin(event) {
    event.preventDefault();
    const btn = document.getElementById("loginBtn");
    const username = document.getElementById("loginUser").value.trim();
    const password = document.getElementById("loginPass").value;

    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Signing in...';

    try {
        const data = await apiRequest("/api/auth/login", "POST", {
            username,
            password,
        });
        showMessage("authMessage", data.message, false);

        // Transition to dashboard
        setTimeout(() => {
            document.getElementById("authContainer").style.display = "none";
            document.getElementById("dashboard").style.display = "block";
            document.getElementById("welcomeUser").textContent = username;
        }, 800);
    } catch (error) {
        showMessage("authMessage", error.message, true);
    } finally {
        btn.disabled = false;
        btn.innerHTML = "Sign In";
    }
}

// ---- Register Handler ----
async function handleRegister(event) {
    event.preventDefault();
    const btn = document.getElementById("regBtn");
    const username = document.getElementById("regUser").value.trim();
    const password = document.getElementById("regPass").value;

    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Creating account...';

    try {
        const data = await apiRequest("/api/auth/register", "POST", {
            username,
            password,
        });
        showMessage("authMessage", data.message + " Please login.", false);
        setTimeout(() => switchTab("login"), 1500);
    } catch (error) {
        showMessage("authMessage", error.message, true);
    } finally {
        btn.disabled = false;
        btn.innerHTML = "Create Account";
    }
}

// ---- Greeting (Async API Test) ----
async function fetchGreeting() {
    const name = document.getElementById("greetName").value.trim() || "World";
    const resultEl = document.getElementById("greetingResult");

    resultEl.innerHTML = '<span class="spinner"></span> Fetching from secure API...';

    try {
        const data = await apiRequest(
            `/api/greeting?name=${encodeURIComponent(name)}`,
            "GET"
        );
        resultEl.innerHTML = `<strong>${data.message}</strong><br><small>Timestamp: ${data.timestamp}</small>`;
    } catch (error) {
        resultEl.innerHTML = `<span style="color:#ff5252">Error: ${error.message}</span>`;
    }
}

// ---- Logout ----
function logout() {
    document.getElementById("dashboard").style.display = "none";
    document.getElementById("authContainer").style.display = "block";
    document.getElementById("loginUser").value = "";
    document.getElementById("loginPass").value = "";
    document.getElementById("authMessage").style.display = "none";
}
