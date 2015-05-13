/*
 * This target marks packets to be enqueued to an imq device
 */
#include <linux/module.h>
#include <linux/skbuff.h>
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter/xt_IMQ.h>
#include <linux/imq.h>

static unsigned int
imq_target(struct sk_buff *skb, const struct xt_action_param *par)
{
	const struct xt_imq_info *mr = par->targinfo;

	skb->imq_flags = mr->todev | IMQ_F_ENQUEUE;

	return XT_CONTINUE;
}

static bool imq_checkentry(const struct xt_tgchk_param *par)
{
	struct xt_imq_info *mr = par->targinfo;

	if (mr->todev > IMQ_MAX_DEVS) {
		printk(KERN_WARNING
		       "IMQ: invalid device specified, highest is %u\n",
		       IMQ_MAX_DEVS);
		return false;
	}

	return true;
}

static struct xt_target xt_imq_reg __read_mostly = {
	.name		= "IMQ",
	.family		= NFPROTO_UNSPEC,
	.target		= imq_target,
	.targetsize	= sizeof(struct xt_imq_info),
	.checkentry	= imq_checkentry,
	.table		= "mangle",
	.me		= THIS_MODULE,
};

static int __init init(void)
{
	return xt_register_target(&xt_imq_reg);
}

static void __exit fini(void)
{
	xt_unregister_target(&xt_imq_reg);
}

module_init(init);
module_exit(fini);

MODULE_AUTHOR("http://www.linuximq.net");
MODULE_DESCRIPTION("Pseudo-driver for the intermediate queue device. See http://www.linuximq.net/ for more information.");
MODULE_LICENSE("GPL");
MODULE_ALIAS("ipt_IMQ");
