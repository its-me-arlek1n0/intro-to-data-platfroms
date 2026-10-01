SSH_KEY="$HOME/.ssh/team_internal"
SSH_USER="team"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5"
SSH="ssh $SSH_OPTS"

NAMENODE="team-11-nn"
SECONDARY_NN="team-11-en"
DATANODES="team-11-en team-11-00 team-11-01"
ALL_NODES="team-11-en team-11-nn team-11-00 team-11-01"

HADOOP_VERSION="3.4.2"
HADOOP_TARBALL="hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_TARBALL}"

HADOOP_HOME="/opt/hadoop"
DATA_DIR="/opt/hadoop/data"
