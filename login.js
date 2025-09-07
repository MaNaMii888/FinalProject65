import { auth, db } from "./firebase.js";
import { signInWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js";

const form = document.getElementById("loginForm");
const errorMsg = document.getElementById("errorMsg");

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const uid = userCredential.user.uid;

    // ตรวจ role จาก Firestore
    const userDoc = await getDoc(doc(db, "users", uid));
    if (userDoc.exists() && userDoc.data().role === "admin") {
      localStorage.setItem("isAdmin", "true");
      window.location.href = "dashboard.html";
    } else {
      errorMsg.textContent = "คุณไม่มีสิทธิ์เข้าใช้งาน Admin Panel";
    }
  } catch (err) {
    errorMsg.textContent = "เข้าสู่ระบบไม่สำเร็จ: " + err.message;
  }
});
