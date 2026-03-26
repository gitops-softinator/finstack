import React, { useState } from "react";
import axios from "axios";

export default function App() {

  const [users, setUsers] = useState([]);

  const fetchUsers = async () => {
    const res = await axios.get("http://localhost:3000/users");
    setUsers(res.data);
  };

  return (
    <div>
      <h1>FinStack Dashboard</h1>

      <button onClick={fetchUsers}>Load Users</button>

      <ul>
        {users.map(u => (
          <li key={u._id}>{u.name}</li>
        ))}
      </ul>
    </div>
  );
}
