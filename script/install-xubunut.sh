sudo apt update
sudo apt upgrade -y
sudo apt install -y ansible git 
git clone https://github.com/scimbe/ansible-ubuntu-basic.git
cd ansible-ubuntu-basic
ansible-galaxy install -r requirements.yml
ansible-playbook -i localhost.ini plattform/xubuntu-xfce4.yml
