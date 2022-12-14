import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

// Testing tips
// https://hardhat.org/tutorial/testing-contracts

describe("Blog", async () => {
	async function deployBlog() {
		const Blog = await hre.ethers.getContractFactory("Blog");
		const [owner, addr1, addr2] = await hre.ethers.getSigners();

		const blog = await Blog.deploy("Blogger");
		await blog.deployed();

		return {
			blog,
			owner,
			addr1,
			addr2,
		};
	}

	it("Should set right owner", async () => {
		const { owner, blog } = await loadFixture(deployBlog);
		expect(await blog.owner()).to.equal(owner.address);
	});

	it("Should create post", async () => {
		const { owner, blog } = await loadFixture(deployBlog);
		await blog.createPost("My first post", "Hello world!");
		const posts = await blog.fetchPosts();

		expect(posts[0].title).to.equal("My first post");
	});

	it("Should create post, based on author", async () => {
		const { owner, addr1, blog } = await loadFixture(deployBlog);

		await blog.connect(owner).createPost("My first post", "Hello world!");
		const ownerPosts = await blog.connect(owner).fetchPostsByAuthor();
		const addr1Posts = await blog.connect(addr1).fetchPostsByAuthor();

		expect(ownerPosts[0].title).to.equal("My first post");
		expect(ownerPosts[0].author).to.equal(owner.address);
		expect(addr1Posts.length).to.equal(0);
	});

	it("Should publish post", async () => {
		const { blog, owner } = await loadFixture(deployBlog);

		await blog.connect(owner).createPost("My first post", "Hello world!");

		const recentPost = await blog.fetchPost("Hello world!");
		expect(recentPost.title).to.equal("My first post");
		expect(recentPost.published).to.equal(false);

		await blog.connect(owner).publishPost(1);
		const publishedRecentPost = await blog.fetchPost("Hello world!");
		expect(publishedRecentPost.title).to.equal("My first post");
		expect(publishedRecentPost.published).to.equal(true);
		expect(publishedRecentPost.publishedAt).to.not.eq(0);
	});

	it("Should update post", async () => {
		const { blog, owner } = await loadFixture(deployBlog);

		await blog.connect(owner).createPost("My first post", "Hello world!");

		const recentPost = await blog.fetchPost("Hello world!");
		expect(recentPost.title).to.equal("My first post");

		await blog
			.connect(owner)
			.updatePost(1, "My first post updated", "Goodbye world!");

		const post = await blog.fetchPostById(1);
		expect(post.title).to.equal("My first post updated");
		expect(post.content).to.equal("Goodbye world!");
	});

	it("Should support multiple authors", async () => {
		const { blog, owner, addr1, addr2 } = await loadFixture(deployBlog);

		await blog.connect(owner).createPost("My first post", "Hello world!");
		await blog.connect(owner).createPost("My second post", "Hello Lisbon!");
		await blog.connect(owner).createPost("My third post", "Hello Singapore!");

		await blog.connect(addr1).createPost("Your first post", "Goodbye world!");
		await blog.connect(addr1).createPost("Your second post", "Goodbye Lisbon!");

		await blog.connect(addr2).createPost("Their first post", "I like you!");

		const ownerPosts = await blog.connect(owner).fetchPostsByAuthor();
		const addr1Posts = await blog.connect(addr1).fetchPostsByAuthor();
		const addr2Posts = await blog.connect(addr2).fetchPostsByAuthor();

		expect(ownerPosts.length).to.equal(3);
		expect(addr1Posts.length).to.equal(2);
		expect(addr2Posts.length).to.equal(1);

		expect(ownerPosts[0].title).to.equal("My first post");
		expect(addr1Posts[0].title).to.equal("Your first post");
		expect(addr2Posts[0].title).to.equal("Their first post");

		expect(ownerPosts[0].author).to.equal(owner.address);
		expect(addr1Posts[0].author).to.equal(addr1.address);
		expect(addr2Posts[0].author).to.equal(addr2.address);
	});

	it("Should not update post, due to different author", async () => {
		const { blog, owner, addr1 } = await loadFixture(deployBlog);

		await blog.connect(owner).createPost("My first post", "Hello world!");

		const recentPost = await blog.fetchPost("Hello world!");
		expect(recentPost.title).to.equal("My first post");

		await expect(
			blog
				.connect(addr1)
				.updatePost(recentPost.id, "My first post updated", "Goodbye world!")
		).to.be.revertedWith("Current caller is not the post's author");
	});
});
