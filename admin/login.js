import { auth, db } from "./firebase.js";
import { signInWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js";

const form = document.getElementById("loginForm");
const msg = document.getElementById("msg");

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;

  msg.textContent = "กำลังเข้าสู่ระบบ...";
  msg.style.color = "#667eea";

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const uid = userCredential.user.uid;

    // ตรวจ role จาก Firestore
    const userDoc = await getDoc(doc(db, "users", uid));
    if (userDoc.exists() && userDoc.data().role === "admin") {
      window.location.href = "index.html";
    } else {
      msg.textContent = "❌ คุณไม่มีสิทธิ์เข้าใช้งาน Admin Panel";
      msg.style.color = "#e74c3c";
    }
  } catch (err) {
    msg.textContent = "⚠️ เข้าสู่ระบบไม่สำเร็จ: " + err.message;
    msg.style.color = "#e74c3c";
  }
});
