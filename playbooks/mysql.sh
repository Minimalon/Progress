ansible-playbook -i hosts/allhosts -v mysql.yml | grep UNREACHABLE > log/mysql.log
