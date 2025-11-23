import { collection, getDocs, deleteDoc, doc, updateDoc, query, orderBy, limit, getDoc } 
  from "https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js";
import { db, auth } from "./firebase.js";
import { signOut } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-auth.js";

// DOM Elements
const logoutBtn = document.getElementById("logoutBtn");
const pageTitle = document.getElementById("pageTitle");

// Posts Elements
const postsTable = document.getElementById("postsTable");
const searchInput = document.getElementById("searchInput");
const buildingFilter = document.getElementById("buildingFilter");
const statusFilter = document.getElementById("statusFilter");

// Users Elements  
const usersTable = document.getElementById("usersTable");
const userSearchInput = document.getElementById("userSearchInput");
const roleFilter = document.getElementById("roleFilter");

// Notifications Elements
const notificationsTable = document.getElementById("notificationsTable");
const notifSearchInput = document.getElementById("notifSearchInput");
const notifStatusFilter = document.getElementById("notifStatusFilter");

// Modal
const postModal = document.getElementById("postModal");
const modalClose = document.querySelector(".close");

let allPosts = [];
let allUsers = [];
let allNotifications = [];
let currentSection = 'dashboard';

// ---------- Navigation ----------
document.querySelectorAll('.nav-link').forEach(link => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    const section = e.currentTarget.dataset.section;
    switchSection(section);
  });
});

function switchSection(section) {
  currentSection = section;
  
  // Update nav active state
  document.querySelectorAll('.nav-link').forEach(link => {
    link.classList.remove('active');
  });
  document.querySelector(`[data-section="${section}"]`).classList.add('active');
  
  // Update sections visibility
  document.querySelectorAll('.section').forEach(sec => {
    sec.classList.remove('active');
  });
  document.getElementById(section).classList.add('active');
  
  // Update title
  const titles = {
    dashboard: 'Dashboard',
    posts: 'จัดการโพสต์',
    users: 'จัดการผู้ใช้',
    notifications: 'การแจ้งเตือน'
  };
  pageTitle.textContent = titles[section];
  
  // Load data for section
  if (section === 'dashboard') loadDashboard();
  else if (section === 'posts') loadPosts();
  else if (section === 'users') loadUsers();
  else if (section === 'notifications') loadNotifications();
}

// ---------- Dashboard ----------
async function loadDashboard() {
  try {
    // Load posts
    const postsSnapshot = await getDocs(collection(db, "lost_found_items"));
    allPosts = postsSnapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    
    // Load users
    const usersSnapshot = await getDocs(collection(db, "users"));
    allUsers = usersSnapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    
    // Calculate statistics
    const lostCount = allPosts.filter(p => p.isLostItem).length;
    const foundCount = allPosts.filter(p => !p.isLostItem).length;
    
    document.getElementById('totalPosts').textContent = allPosts.length;
    document.getElementById('lostItems').textContent = lostCount;
    document.getElementById('foundItems').textContent = foundCount;
    document.getElementById('totalUsers').textContent = allUsers.length;
    
    // Recent posts
    const recentPosts = [...allPosts]
      .sort((a, b) => {
        const dateA = getPostDate(a);
        const dateB = getPostDate(b);
        
        let timeA, timeB;
        if (dateA?.toDate) timeA = dateA.toDate().getTime();
        else if (dateA?.seconds) timeA = dateA.seconds * 1000;
        else if (dateA) timeA = new Date(dateA).getTime();
        else timeA = 0;
        
        if (dateB?.toDate) timeB = dateB.toDate().getTime();
        else if (dateB?.seconds) timeB = dateB.seconds * 1000;
        else if (dateB) timeB = new Date(dateB).getTime();
        else timeB = 0;
        
        return timeB - timeA;
      })
      .slice(0, 5);
    
    displayRecentPosts(recentPosts);
    
    // Category stats
    displayCategoryStats();
  } catch (error) {
    console.error("Error loading dashboard:", error);
  }
}

function displayRecentPosts(posts) {
  const container = document.getElementById('recentPosts');
  if (posts.length === 0) {
    container.innerHTML = '<p class="empty-state">ไม่มีโพสต์</p>';
    return;
  }
  
  container.innerHTML = posts.map(post => `
    <div class="recent-item">
      <div class="recent-icon ${post.isLostItem ? 'lost' : 'found'}">
        <i class="fas ${post.isLostItem ? 'fa-search' : 'fa-check-circle'}"></i>
      </div>
      <div class="recent-info">
        <strong>${post.title || post.detail || 'ไม่มีชื่อ'}</strong>
        <small>${post.building || 'ไม่ระบุ'} | ${post.categoryName || 'ไม่ระบุหมวดหมู่'}</small>
      </div>
      <span class="recent-badge ${post.isLostItem ? 'badge-lost' : 'badge-found'}">
        ${post.isLostItem ? 'หาย' : 'เจอ'}
      </span>
    </div>
  `).join('');
}

function displayCategoryStats() {
  const container = document.getElementById('categoryStats');
  const categories = {};
  
  allPosts.forEach(post => {
    const cat = post.categoryName || 'ไม่ระบุ';
    categories[cat] = (categories[cat] || 0) + 1;
  });
  
  const sorted = Object.entries(categories)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
  
  if (sorted.length === 0) {
    container.innerHTML = '<p class="empty-state">ไม่มีข้อมูล</p>';
    return;
  }
  
  const maxCount = sorted[0][1];
  
  container.innerHTML = sorted.map(([cat, count]) => `
    <div class="category-item">
      <div class="category-name">${cat}</div>
      <div class="category-bar">
        <div class="category-fill" style="width: ${(count / maxCount) * 100}%"></div>
      </div>
      <div class="category-count">${count}</div>
    </div>
  `).join('');
}

// ---------- Posts Management ----------
async function loadPosts() {
  if (allPosts.length === 0) {
    const snapshot = await getDocs(collection(db, "lost_found_items"));
    allPosts = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
  }
  populateBuildingFilter();
  displayPosts(allPosts);
}

function populateBuildingFilter() {
  // รายการอาคารทั้งหมดเรียงตามลำดับ
  const allBuildings = [
    'อาคาร 1',
    'อาคาร 2',
    'อาคาร 3',
    'อาคาร 4',
    'อาคาร 5',
    'อาคาร 6',
    'อาคาร 7',
    'อาคาร 8',
    'อาคาร 9',
    'อาคาร 10',
    'อาคาร 11',
    'อาคาร 12',
    'อาคาร 15',
    'อาคาร 16',
    'อาคาร 17',
    'อาคาร 18',
    'อาคาร 19',
    'อาคาร 20',
    'อาคาร 22',
    'อาคาร 24',
    'อาคาร 26',
    'อาคาร 27',
    'อาคาร 28',
    'อาคาร 29',
    'อาคาร 30',
    'อาคาร 31',
    'อาคาร 33',
    'โรงอาหาร',
    'ห้องสมุด',
    'สำนักงาน',
    'สนาม',
  ];
  
  buildingFilter.innerHTML = `<option value="">ทุกอาคาร</option>` +
    allBuildings.map(b => `<option value="${b}">${b}</option>`).join("");
}

function displayPosts(posts) {
  if (posts.length === 0) {
    postsTable.innerHTML = '<tr><td colspan="9" class="empty-state">ไม่พบข้อมูล</td></tr>';
    return;
  }
  
  postsTable.innerHTML = posts.map(post => {
    const postDate = getPostDate(post);
    return `
    <tr>
      <td>${post.imageUrl ? `<img src="${post.imageUrl}" alt="รูปภาพ" class="table-img">` : "-"}</td>
      <td class="td-detail">${post.title || post.detail || "-"}</td>
      <td>${post.categoryName || "-"}</td>
      <td>${post.building || "-"}</td>
      <td>${post.room || post.location || "-"}</td>
      <td><span class="badge ${post.isLostItem ? 'badge-lost' : 'badge-found'}">${post.isLostItem ? "Lost" : "Found"}</span></td>
      <td>${post.contact || "-"}</td>
      <td>${formatDate(postDate)}</td>
      <td class="action-cell">
        <button class="btn-icon btn-view" onclick="viewPost('${post.id}')" title="ดูรายละเอียด">
          <i class="fas fa-eye"></i>
        </button>
        <button class="btn-icon btn-delete" onclick="deletePost('${post.id}')" title="ลบ">
          <i class="fas fa-trash"></i>
        </button>
      </td>
    </tr>
  `;
  }).join('');
}

window.viewPost = async function(id) {
  const post = allPosts.find(p => p.id === id);
  if (!post) return;
  
  // ดึงชื่อผู้ใช้จริง
  const posterName = await getUserName(post.userId);
  const postDate = getPostDate(post);
  
  const details = document.getElementById('postDetails');
  details.innerHTML = `
    <h2>${post.title || post.detail || 'ไม่มีชื่อ'}</h2>
    <div class="modal-grid">
      ${post.imageUrl ? `<img src="${post.imageUrl}" alt="รูปภาพ" class="modal-img">` : ''}
      <div class="modal-info">
        <p><strong>ประเภท:</strong> <span class="badge ${post.isLostItem ? 'badge-lost' : 'badge-found'}">${post.isLostItem ? 'ของหาย' : 'ของเจอ'}</span></p>
        <p><strong>หมวดหมู่:</strong> ${post.categoryName || 'ไม่ระบุ'}</p>
        <p><strong>อาคาร:</strong> ${post.building || 'ไม่ระบุ'}</p>
        <p><strong>ห้อง/สถานที่:</strong> ${post.room || post.location || 'ไม่ระบุ'}</p>
        <p><strong>ติดต่อ:</strong> ${post.contact || 'ไม่ระบุ'}</p>
        <p><strong>วันที่:</strong> ${formatDate(postDate)}</p>
        <p><strong>รายละเอียด:</strong><br>${post.description || post.detail || 'ไม่มี'}</p>
        <p><strong>ผู้โพสต์:</strong> ${posterName}</p>
        <p><strong>ผู้โพสต์ ID:</strong> ${post.userId || 'ไม่ระบุ'}</p>
      </div>
    </div>
  `;
  postModal.style.display = 'block';
}

window.deletePost = async function(id) {
  if (confirm("คุณต้องการลบโพสต์นี้ไหม?")) {
    try {
      await deleteDoc(doc(db, "lost_found_items", id));
      allPosts = allPosts.filter(p => p.id !== id);
      displayPosts(allPosts);
      alert('ลบสำเร็จ');
    } catch (error) {
      console.error("Error deleting post:", error);
      alert('เกิดข้อผิดพลาด: ' + error.message);
    }
  }
}

function filterPosts() {
  const query = searchInput.value.toLowerCase();
  const building = buildingFilter.value;
  const status = statusFilter.value;

  const filtered = allPosts.filter(p => {
    const values = [
      p.title,
      p.detail,
      p.description,
      p.categoryName,
      p.building,
      p.room,
      p.location,
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

if (searchInput) searchInput.addEventListener("input", filterPosts);
if (buildingFilter) buildingFilter.addEventListener("change", filterPosts);
if (statusFilter) statusFilter.addEventListener("change", filterPosts);

// ---------- Users Management ----------
async function loadUsers() {
  try {
    // Force reload from Firestore
    const usersSnapshot = await getDocs(collection(db, "users"));
    allUsers = usersSnapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    
    // Count posts per user
    if (allPosts.length === 0) {
      const postsSnapshot = await getDocs(collection(db, "lost_found_items"));
      allPosts = postsSnapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    }
    
    displayUsers(allUsers);
    console.log('✅ Loaded', allUsers.length, 'users');
  } catch (error) {
    console.error("Error loading users:", error);
  }
}

// Refresh users data
window.refreshUsers = async function() {
  console.log('🔄 Refreshing users...');
  await loadUsers();
  alert('รีเฟรชข้อมูลผู้ใช้เรียบร้อย (' + allUsers.length + ' คน)');
}

function displayUsers(users) {
  if (users.length === 0) {
    usersTable.innerHTML = '<tr><td colspan="7" class="empty-state">ไม่พบข้อมูล</td></tr>';
    return;
  }
  
  usersTable.innerHTML = users.map(user => {
    const userPostCount = allPosts.filter(p => p.userId === user.id).length;
    
    // ถ้าไม่มี createdAt ให้ลอง lastLogin หรือแสดง "ไม่ระบุ"
    const dateToShow = user.createdAt || user.lastLogin || user.metadata?.creationTime;
    
    return `
      <tr>
        <td class="td-uid">${user.id.substring(0, 8)}...</td>
        <td>${user.email || 'ไม่ระบุ'}</td>
        <td>${user.name || user.displayName || 'ไม่ระบุ'}</td>
        <td><span class="badge ${user.role === 'admin' ? 'badge-admin' : 'badge-user'}">${user.role || 'user'}</span></td>
        <td>${userPostCount}</td>
        <td>${formatDate(dateToShow)}</td>
        <td class="action-cell">
          <button class="btn-icon btn-edit" onclick="toggleRole('${user.id}')" title="เปลี่ยน Role">
            <i class="fas fa-user-cog"></i>
          </button>
          <button class="btn-icon btn-delete" onclick="deleteUser('${user.id}')" title="ลบ">
            <i class="fas fa-trash"></i>
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

window.toggleRole = async function(userId) {
  const user = allUsers.find(u => u.id === userId);
  if (!user) return;
  
  const newRole = user.role === 'admin' ? 'user' : 'admin';
  
  if (confirm(`เปลี่ยน Role จาก "${user.role || 'user'}" เป็น "${newRole}"?`)) {
    try {
      await updateDoc(doc(db, "users", userId), { role: newRole });
      user.role = newRole;
      displayUsers(allUsers);
      alert('อัพเดท Role สำเร็จ');
    } catch (error) {
      console.error("Error updating role:", error);
      alert('เกิดข้อผิดพลาด: ' + error.message);
    }
  }
}

window.deleteUser = async function(userId) {
  if (confirm("คุณต้องการลบผู้ใช้นี้ไหม? (จะลบโพสต์ทั้งหมดของผู้ใช้ด้วย)")) {
    try {
      // Delete user's posts
      const userPosts = allPosts.filter(p => p.userId === userId);
      for (const post of userPosts) {
        await deleteDoc(doc(db, "lost_found_items", post.id));
      }
      
      // Delete user
      await deleteDoc(doc(db, "users", userId));
      
      allUsers = allUsers.filter(u => u.id !== userId);
      allPosts = allPosts.filter(p => p.userId !== userId);
      displayUsers(allUsers);
      alert('ลบผู้ใช้และโพสต์สำเร็จ');
    } catch (error) {
      console.error("Error deleting user:", error);
      alert('เกิดข้อผิดพลาด: ' + error.message);
    }
  }
}

function filterUsers() {
  const query = userSearchInput.value.toLowerCase();
  const role = roleFilter.value;
  
  const filtered = allUsers.filter(u => {
    const matchesSearch = (u.email || '').toLowerCase().includes(query) ||
                         (u.name || '').toLowerCase().includes(query) ||
                         (u.displayName || '').toLowerCase().includes(query);
    const matchesRole = role ? u.role === role : true;
    
    return matchesSearch && matchesRole;
  });
  
  displayUsers(filtered);
}

if (userSearchInput) userSearchInput.addEventListener("input", filterUsers);
if (roleFilter) roleFilter.addEventListener("change", filterUsers);

// ---------- Notifications Management ----------
async function loadNotifications() {
  try {
    const notifsSnapshot = await getDocs(collection(db, "notifications"));
    allNotifications = notifsSnapshot.docs.map(d => ({ id: d.id, ...d.data() }));
    displayNotifications(allNotifications);
  } catch (error) {
    console.error("Error loading notifications:", error);
  }
}

function displayNotifications(notifs) {
  if (notifs.length === 0) {
    notificationsTable.innerHTML = '<tr><td colspan="8" class="empty-state">ไม่พบข้อมูล</td></tr>';
    return;
  }
  
  notificationsTable.innerHTML = notifs.map(notif => {
    // หาชื่อผู้รับแจ้งเตือน
    const recipient = allUsers.find(u => u.id === notif.userId);
    const recipientName = recipient ? (recipient.name || recipient.displayName || recipient.email) : 'ไม่ระบุ';
    
    // หาชื่อผู้โพสต์จาก data.userName หรือค้นหาใน allUsers
    let posterName = 'ไม่ระบุ';
    if (notif.data?.userName) {
      posterName = notif.data.userName;
    } else if (notif.postId) {
      // หาโพสต์แล้วดึง userId
      const post = allPosts.find(p => p.id === notif.postId);
      if (post) {
        const poster = allUsers.find(u => u.id === post.userId);
        posterName = poster ? (poster.name || poster.displayName || poster.email) : 'ไม่ระบุ';
      }
    }
    
    return `
    <tr>
      <td class="td-uid">${recipientName}</td>
      <td><span class="badge badge-info">${notif.type || 'smart_match'}</span></td>
      <td class="td-detail">${notif.title || 'ไม่มีชื่อ'}</td>
      <td>${posterName}</td>
      <td>${notif.matchScore ? `${Math.round(notif.matchScore * 100)}%` : '-'}</td>
      <td><span class="badge ${notif.isRead ? 'badge-found' : 'badge-lost'}">${notif.isRead ? 'อ่านแล้ว' : 'ยังไม่อ่าน'}</span></td>
      <td>${formatDate(notif.createdAt)}</td>
      <td class="action-cell">
        <button class="btn-icon btn-delete" onclick="deleteNotification('${notif.id}')" title="ลบ">
          <i class="fas fa-trash"></i>
        </button>
      </td>
    </tr>
  `;
  }).join('');
}

window.deleteNotification = async function(id) {
  if (confirm("คุณต้องการลบการแจ้งเตือนนี้ไหม?")) {
    try {
      await deleteDoc(doc(db, "notifications", id));
      allNotifications = allNotifications.filter(n => n.id !== id);
      displayNotifications(allNotifications);
      alert('ลบสำเร็จ');
    } catch (error) {
      console.error("Error deleting notification:", error);
      alert('เกิดข้อผิดพลาด: ' + error.message);
    }
  }
}

function filterNotifications() {
  const query = notifSearchInput.value.toLowerCase();
  const status = notifStatusFilter.value;
  
  const filtered = allNotifications.filter(n => {
    const matchesSearch = (n.title || '').toLowerCase().includes(query) ||
                         (n.body || '').toLowerCase().includes(query);
    const matchesStatus = status ? n.isRead.toString() === status : true;
    
    return matchesSearch && matchesStatus;
  });
  
  displayNotifications(filtered);
}

if (notifSearchInput) notifSearchInput.addEventListener("input", filterNotifications);
if (notifStatusFilter) notifStatusFilter.addEventListener("change", filterNotifications);

// ---------- Utilities ----------
// ดึงวันที่จากโพสต์ (รองรับหลาย field)
function getPostDate(post) {
  // ลองดึงจาก field ต่างๆ
  const dateField = post.createdAt || post.date || post.timestamp || post.created;
  return dateField;
}

function formatDate(date) {
  if (!date) return 'ไม่ระบุ';
  
  try {
    let d;
    if (date.toDate && typeof date.toDate === 'function') {
      // Firebase Timestamp
      d = date.toDate();
    } else if (date.seconds) {
      // Firebase Timestamp object
      d = new Date(date.seconds * 1000);
    } else if (typeof date === 'string' || typeof date === 'number') {
      d = new Date(date);
    } else if (date instanceof Date) {
      d = date;
    } else {
      return 'ไม่ระบุ';
    }
    
    // ตรวจสอบว่าเป็น valid date
    if (!d || isNaN(d.getTime())) {
      return 'ไม่ระบุ';
    }
    
    return d.toLocaleDateString('th-TH', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch (error) {
    console.error('Date format error:', error, date);
    return 'ไม่ระบุ';
  }
}

// ดึงชื่อผู้ใช้จริงจาก userId
async function getUserName(userId) {
  if (!userId) return 'ไม่ระบุ';
  
  try {
    // หาจาก cache ก่อน
    const cachedUser = allUsers.find(u => u.id === userId);
    if (cachedUser) {
      return cachedUser.name || cachedUser.displayName || cachedUser.email || userId;
    }
    
    // ถ้าไม่มีใน cache ให้ดึงจาก Firestore
    const userDoc = await getDoc(doc(db, 'users', userId));
    if (userDoc.exists()) {
      const userData = userDoc.data();
      return userData.name || userData.displayName || userData.email || userId;
    }
    
    return userId;
  } catch (error) {
    console.error('Error getting user name:', error);
    return userId;
  }
}

// ---------- Modal ----------
if (modalClose) {
  modalClose.onclick = () => postModal.style.display = 'none';
}

window.onclick = (e) => {
  if (e.target == postModal) {
    postModal.style.display = 'none';
  }
}

// ---------- Log Out ----------
logoutBtn.addEventListener("click", async () => {
  await signOut(auth);
  window.location.href = "login.html";
});

// ---------- Initialize ----------
loadDashboard();
