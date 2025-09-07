import { collection, getDocs, deleteDoc, doc } 
  from "https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js";
import { db, auth } from "./firebase.js";
import { signOut } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-auth.js";

const table = document.getElementById("postsTable");
const searchInput = document.getElementById("searchInput");
const buildingFilter = document.getElementById("buildingFilter");
const statusFilter = document.getElementById("statusFilter");
const logoutBtn = document.getElementById("logoutBtn");

let allPosts = [];

// ---------- Load posts ----------
async function loadPosts() {
  const snapshot = await getDocs(collection(db, "lost_found_items"));
  allPosts = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
  populateBuildingFilter();
  displayPosts(allPosts);
}

// ---------- Populate Building Filter ----------
function populateBuildingFilter() {
  const buildings = [...new Set(allPosts.map(p => p.building).filter(b => b))];
  buildingFilter.innerHTML = `<option value="">ทุกอาคาร</option>` +
    buildings.map(b => `<option value="${b}">${b}</option>`).join("");
}

// ---------- Display posts ----------
function displayPosts(posts) {
  table.innerHTML = "";
  posts.forEach(post => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${post.imageUrl ? `<img src="${post.imageUrl}" alt="รูปภาพ">` : "-"}</td>
      <td>${post.detail || "-"}</td>
      <td>${post.categoryName || "-"}</td>
      <td>${post.building || "-"}</td>
      <td>${post.room || "-"}</td>
      <td>${post.isLostItem ? "Lost" : "Found"}</td>
      <td>${post.contact || "-"}</td>
      <td>${post.date || "-"}</td>
      <td><button class="btn-delete" onclick="deletePost('${post.id}')">Delete</button></td>
    `;
    table.appendChild(tr);
  });
}

// ---------- Delete post ----------
window.deletePost = async function(id) {
  if (confirm("คุณต้องการลบโพสต์นี้ไหม?")) {
    await deleteDoc(doc(db, "lost_found_items", id));
    await loadPosts();
  }
}

// ---------- Filter/Search ----------
function filterPosts() {
  const query = searchInput.value.toLowerCase();
  const building = buildingFilter.value;
  const status = statusFilter.value;

  const filtered = allPosts.filter(p => {
    const values = [
      p.detail,
      p.categoryName,
      p.building,
      p.room,
      p.contact,
      p.date,
      p.isLostItem ? "Lost" : "Found"
    ].filter(v => v).map(v => v.toString().toLowerCase());

    const matchesSearch = values.some(v => v.includes(query));
    const matchesBuilding = building ? p.building === building : true;
    const matchesStatus = status ? (p.isLostItem ? "Lost" : "Found") === status : true;

    return matchesSearch && matchesBuilding && matchesStatus;
  });

  displayPosts(filtered);
}

searchInput.addEventListener("input", filterPosts);
buildingFilter.addEventListener("change", filterPosts);
statusFilter.addEventListener("change", filterPosts);

// ---------- Log Out ----------
logoutBtn.addEventListener("click", async () => {
  await signOut(auth);
  window.location.href = "login.html";
});

// ---------- Load initial ----------
loadPosts();
