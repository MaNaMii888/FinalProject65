# Code Citations

## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId}
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth !=
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null &&
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.ui
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth !=
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.
```


## License: unknown
https://github.com/suzu1997/Movie-notes-app/blob/4dd2d80f55cda6b803a5e7c6e631a85d20850311/firestore.rules

```
.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid =
```

