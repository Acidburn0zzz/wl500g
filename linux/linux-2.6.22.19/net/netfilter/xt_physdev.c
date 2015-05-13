/* Kernel module to match the bridge port in and
 * out device for IP packets coming into contact with a bridge. */

/* (C) 2001-2003 Bart De Schuymer <bdschuym@pandora.be>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/module.h>
#include <linux/skbuff.h>
#include <linux/netfilter_bridge.h>
#include <linux/netfilter/xt_physdev.h>
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter_bridge.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Bart De Schuymer <bdschuym@pandora.be>");
MODULE_DESCRIPTION("iptables bridge physical device match module");
MODULE_ALIAS("ipt_physdev");
MODULE_ALIAS("ip6t_physdev");

static bool
match(const struct sk_buff *skb, struct xt_action_param *par)
{
	static const char nulldevname[IFNAMSIZ] __attribute__((aligned(sizeof(long))));
	const struct xt_physdev_info *info = par->matchinfo;
	unsigned long ret;
	const char *indev, *outdev;
	struct nf_bridge_info *nf_bridge;

	/* Not a bridged IP packet or no info available yet:
	 * LOCAL_OUT/mangle and LOCAL_OUT/nat don't know if
	 * the destination device will be a bridge. */
	if (!(nf_bridge = skb->nf_bridge)) {
		/* Return MATCH if the invert flags of the used options are on */
		if ((info->bitmask & XT_PHYSDEV_OP_BRIDGED) &&
		    !(info->invert & XT_PHYSDEV_OP_BRIDGED))
			return NOMATCH;
		if ((info->bitmask & XT_PHYSDEV_OP_ISIN) &&
		    !(info->invert & XT_PHYSDEV_OP_ISIN))
			return NOMATCH;
		if ((info->bitmask & XT_PHYSDEV_OP_ISOUT) &&
		    !(info->invert & XT_PHYSDEV_OP_ISOUT))
			return NOMATCH;
		if ((info->bitmask & XT_PHYSDEV_OP_IN) &&
		    !(info->invert & XT_PHYSDEV_OP_IN))
			return NOMATCH;
		if ((info->bitmask & XT_PHYSDEV_OP_OUT) &&
		    !(info->invert & XT_PHYSDEV_OP_OUT))
			return NOMATCH;
		return MATCH;
	}

	/* This only makes sense in the FORWARD and POSTROUTING chains */
	if ((info->bitmask & XT_PHYSDEV_OP_BRIDGED) &&
	    (!!(nf_bridge->mask & BRNF_BRIDGED) ^
	    !(info->invert & XT_PHYSDEV_OP_BRIDGED)))
		return NOMATCH;

	if ((info->bitmask & XT_PHYSDEV_OP_ISIN &&
	    (!nf_bridge->physindev ^ !!(info->invert & XT_PHYSDEV_OP_ISIN))) ||
	    (info->bitmask & XT_PHYSDEV_OP_ISOUT &&
	    (!nf_bridge->physoutdev ^ !!(info->invert & XT_PHYSDEV_OP_ISOUT))))
		return NOMATCH;

	if (!(info->bitmask & XT_PHYSDEV_OP_IN))
		goto match_outdev;
	indev = nf_bridge->physindev ? nf_bridge->physindev->name : nulldevname;
	ret = ifname_compare_aligned(indev, info->physindev, info->in_mask);

	if ((ret == 0) ^ !(info->invert & XT_PHYSDEV_OP_IN))
		return NOMATCH;

match_outdev:
	if (!(info->bitmask & XT_PHYSDEV_OP_OUT))
		return MATCH;
	outdev = nf_bridge->physoutdev ?
		 nf_bridge->physoutdev->name : nulldevname;
	ret = ifname_compare_aligned(outdev, info->physoutdev, info->out_mask);

	return (!!ret ^ !(info->invert & XT_PHYSDEV_OP_OUT));
}

static bool checkentry(const struct xt_mtchk_param *par)
{
	const struct xt_physdev_info *info = par->matchinfo;

	if (!(info->bitmask & XT_PHYSDEV_OP_MASK) ||
	    info->bitmask & ~XT_PHYSDEV_OP_MASK)
		return false;
	if (info->bitmask & XT_PHYSDEV_OP_OUT &&
	    (!(info->bitmask & XT_PHYSDEV_OP_BRIDGED) ||
	     info->invert & XT_PHYSDEV_OP_BRIDGED) &&
	    par->hook_mask & ((1 << NF_IP_LOCAL_OUT) |
	    (1 << NF_IP_FORWARD) | (1 << NF_IP_POST_ROUTING))) {
		printk(KERN_WARNING "physdev match: using --physdev-out in the "
		       "OUTPUT, FORWARD and POSTROUTING chains for non-bridged "
		       "traffic is not supported anymore.\n");
		if (par->hook_mask & (1 << NF_IP_LOCAL_OUT))
			return false;
	}
	return true;
}

static struct xt_match xt_physdev_match __read_mostly = {
	.name		= "physdev",
	.revision   = 0,
	.family		= NFPROTO_UNSPEC,
	.checkentry	= checkentry,
	.match		= match,
	.matchsize	= sizeof(struct xt_physdev_info),
	.me		= THIS_MODULE,
};

static int __init xt_physdev_init(void)
{
	return xt_register_match(&xt_physdev_match);
}

static void __exit xt_physdev_fini(void)
{
	xt_unregister_match(&xt_physdev_match);
}

module_init(xt_physdev_init);
module_exit(xt_physdev_fini);
