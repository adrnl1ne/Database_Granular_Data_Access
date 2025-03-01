# Classified Files Database Access

This repo contains a Docker container with a Microsoft SQL Server 2019 Developer Edition database for granular data access. The container is shared via a release.

## Get the Database

### Download the Image
1. Go to the [Releases page](https://github.com/adrnl1ne/Database_Granular_Data_Access/releases)
2. Download `mssql-snapshot.tar` from the latest release (e.g., v1.0).

### Load the Image
```bash
docker load -i mssql-snapshot.tar
```
(Use the path where you saved it, e.g., `C:\Downloads\mssql-snapshot.tar`.)

### Start the Container
```bash
docker run --name mydb -p 1433:1433 -d mssql-snapshot
```
This runs the database on your machine, mapped to port 1433.

## Connect to the Database
Use these commands in VS Code's terminal or connect via SSMS:

### Users and Passwords:
| User | Password |
|------|----------|
| `basic` | `Basic456!` |
| `viewer` | `View456!` |
| `writer` | `Write456!` |
| `editor` | `Edit456!` |
| `admin` | `Admin123!` |

### Option 1: Terminal with sqlcmd (Compact)
```bash
docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U <username> -P "<password>" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s" "
```
Example: 
```bash
docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U writer -P "Edit456!" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s" "
```

### Option 2: Terminal with sqlcmd (Polished)
```bash
docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U <username> -P "<password>" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
```
Example: 
```bash
docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U writer -P "Edit456!" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
```

### Option 3: SSMS (GUI)
1. Open SSMS.
2. Server Name: `localhost,1433`
3. Authentication: SQL Server Authentication
4. Login: `<username>` (e.g., `writer`)
5. Password: `<password>` (e.g., `Edit456!`)
6. Connect, then run:
  ```sql
  SELECT * FROM ProjectDB.dbo.ClassifiedFiles_Secure;
  ```

## What's Inside
The `ClassifiedFiles` table has:
- **ID**: Unique file number (integer).
- **Filename**: File name (e.g., "memo1.txt").
- **Content**: File contents (e.g., "Public meeting notes").
- **ClearanceLevel**: Security level (1 = low, 2 = medium, 3 = high).
- **Department**: Owning team (e.g., "HR").

### Sample Files:
| Filename | Content | Level | Department |
|----------|---------|-------|------------|
| **memo1.txt** | "Public meeting notes" | 1 | HR |
| **report_q1.pdf** | "Employee performance stats" | 2 | HR |
| **budget_2025.xlsx** | "Financial projections" | 3 | Finance |
| **policy_update.doc** | "New hire guidelines" | 1 | HR |
| **audit_log.txt** | "Internal audit details" | 3 | Finance |
| **survey_results.csv** | "Staff feedback summary" | 2 | Operations |
| **contract_draft.pdf** | "Vendor termsConfidential" | 3 | Legal |
| **training_plan.ppt** | "Basic onboarding slides" | 1 | Training |

## Who Can Do What

| User | Access Level | Rows | Content Visible |
|------|-------------|------|-----------------|
| **basic** | Sees only level 1 files (3 files: "memo1.txt", "policy_update.doc", "training_plan.ppt") without the content column. Can't add or edit files. | 3 | No |
| **viewer** | Sees level 1 and 2 files (5 files, excluding level 3). Can't add or edit files. | 5 | Yes |
| **writer** | Sees all files (8 initially) and can add new files at levels 1, 2, or 3. | 8 | Yes |
| **editor** | Sees all files and can edit the content column of any file. | 8 | Yes |
| **admin** | Full access—sees all files, can add, edit, or delete anything. | 8 | Yes |

## How Cell-Level Granular Access Works
SQL Server uses Row-Level Security (RLS) and a view for cell-level control:
- **Row Access**: RLS policy (`ClassifiedFilesPolicy`) limits rows by `ClearanceLevel`:
  - basic: Only level 1 (3 rows).
  - viewer: Levels 1-2 (5 rows).
  - writer, editor, admin: All levels (8+).
- **Column Access**: `ClassifiedFiles_Secure` view hides `Content` for `basic` using a `CASE` statement—others see all columns, with `editor` able to update `Content`.

## Test It

### Check Access (Should Pass):
1. **basic**: See 3 files without content:
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U basic -P "Basic456!" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

2. **viewer**: See 5 files:
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U viewer -P "View456!" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

3. **writer**: See all 8 files:
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U writer -P "Edit456!" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

4. **admin**: See all 8 files:
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U admin -P "Admin123!" -d ProjectDB -Q "SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

### Try Adding a File (Mixed Results):
1. **writer**: Add a new file (should pass, increases to 9 rows):
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U writer -P "Edit456!" -d ProjectDB -Q "INSERT INTO ClassifiedFiles (Filename, Content, ClearanceLevel, Department) VALUES ('test_file.txt', 'Test content', 1, 'TestDept'); SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

2. **basic**: Try to insert (should fail):
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U basic -P "Basic456!" -d ProjectDB -Q "INSERT INTO ClassifiedFiles (Filename, Content, ClearanceLevel, Department) VALUES ('test_file.txt', 'Test content', 1, 'TestDept');"
  ```
  Expected: "Msg 229, Permission denied"

### Try Updating a Cell (Mixed Results):
1. **editor**: Update content for id 1 (should pass):
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U editor -P "Cell456!" -d ProjectDB -Q "UPDATE ClassifiedFiles SET Content = 'Updated note' WHERE ID = 1; SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

2. **writer**: Try to update (should fail):
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U writer -P "Edit456!" -d ProjectDB -Q "UPDATE ClassifiedFiles SET Content = 'Updated note' WHERE ID = 1;"
  ```
  Expected: "Msg 230, Permission denied on column 'Content'"

### Try Deleting a Row (Should Fail for Most):
1. **admin**: Delete row (should pass):
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U admin -P "Admin123!" -d ProjectDB -Q "DELETE FROM ClassifiedFiles WHERE ID = 1; SELECT * FROM ClassifiedFiles_Secure;" -s"  " -W
  ```

2. **writer**: Try to delete (should fail):
  ```bash
  docker exec -it mydb /opt/mssql-tools/bin/sqlcmd -S localhost -U writer -P "Edit456!" -d ProjectDB -Q "DELETE FROM ClassifiedFiles WHERE ID = 1;"
  ```
  Expected: "Msg 229, Permission denied"

## Notes
- Use `sqlcmd -s"  " -W` for best terminal readability or SSMS for a GUI grid.
- If connection fails, check logs: `docker logs mydb`—look for "SQL Server is now ready."
